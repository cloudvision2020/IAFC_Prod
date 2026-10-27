@IsTest
private class PayflowReportControllerTest {

    private static final String OK_BASE =
        '<baseResponse><responseCode>100</responseCode><responseMsg>Request has completed successfully</responseMsg></baseResponse>';

    private class ReportingMock implements HttpCalloutMock {
        String runStatus;
        String baseOverride;
        List<String> requestBodies = new List<String>();

        ReportingMock(String runStatus) {
            this.runStatus = runStatus;
        }

        public HttpResponse respond(HttpRequest req) {
            String body = req.getBody();
            requestBodies.add(body);
            String base = baseOverride != null ? baseOverride : OK_BASE;
            String payload;
            if (body.contains('<runReportRequest>')) {
                payload = '<runReportResponse><reportId>RE1</reportId><statusCode>' + runStatus
                    + '</statusCode><statusMsg>msg</statusMsg></runReportResponse>';
            } else if (body.contains('<getResultsRequest>') && body.contains('<scheduleName>')) {
                payload = '<getResultsResponse>'
                    + scheduledResult('RE_OLD', '2026-10-01T02:00:00')
                    + scheduledResult('RE_NEW', '2026-10-02T02:00:00')
                    + '</getResultsResponse>';
            } else if (body.contains('<getResultsRequest>')) {
                payload = '<getResultsResponse><Results><reportId>RE1</reportId><statusCode>3</statusCode>'
                    + '<statusMsg>Report has completed successfully</statusMsg></Results></getResultsResponse>';
            } else if (body.contains('<getMetaDataRequest>')) {
                payload = '<getMetaDataResponse><reportId>RE1</reportId><numberOfRows>3</numberOfRows>'
                    + '<numberOfPages>1</numberOfPages><pageSize>50</pageSize><numberOfColumns>4</numberOfColumns>'
                    + column(1, 'Transaction ID') + column(2, 'Type') + column(3, 'Amount') + column(4, 'Batch ID')
                    + '</getMetaDataResponse>';
            } else {
                // European decimals (266,40) must parse as 266.40, not 26640.
                payload = '<getDataResponse><reportId>RE1</reportId><pageNum>1</pageNum>'
                    + row(1, new List<String>{ 'TXN1', 'Sale', '266,40', '407' })
                    + row(2, new List<String>{ 'TXN2', 'Sale', '2.200,00', '407' })
                    + row(3, new List<String>{ 'TXN3', 'Credit', '20,00', '407' })
                    + '</getDataResponse>';
            }

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('<?xml version="1.0" encoding="UTF-8"?><reportingEngineResponse>' + base + payload + '</reportingEngineResponse>');
            return res;
        }

        private String scheduledResult(String reportId, String executionTime) {
            return '<Results><reportId>' + reportId + '</reportId><statusCode>3</statusCode>'
                + '<statusMsg>Report has completed successfully</statusMsg>'
                + '<executionTime>' + executionTime + '</executionTime><scheduleName>Daily Settlement</scheduleName></Results>';
        }

        private String column(Integer num, String name) {
            return '<columnMetaData colNum="' + num + '"><dataName>' + name + '</dataName><dataType>string</dataType></columnMetaData>';
        }

        private String row(Integer num, List<String> values) {
            String xml = '<reportDataRow rowNum="' + num + '">';
            for (Integer i = 0; i < values.size(); i++) {
                xml += '<columnData colNum="' + (i + 1) + '"><data>' + values[i] + '</data></columnData>';
            }
            return xml + '</reportDataRow>';
        }
    }

    @TestSetup
    static void setup() {
        // Subscriber-style namespaced List Custom Setting (matches PayflowReportController).
        insert new s7e__Payment_Setting__c(
            Name = 'Payflow',
            s7e__Live_Mode__c = false,
            s7e__Test_Mode_Username__c = 'user',
            s7e__Test_Mode_Password__c = 'p&ss',
            s7e__Test_Mode_Vendor__c = 'vendor',
            s7e__Test_Mode_Partner__c = 'PayPal'
        );
    }

    @IsTest
    static void runReportLoadsRowsAndBatchTotals() {
        ReportingMock mock = new ReportingMock('3');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        PayflowReportController.ReportResult result = PayflowReportController.runReport(
            'SettlementReport', '2026-07-01', '2026-07-01', 'Settled', 'GMT', 50, 2
        );
        Test.stopTest();

        System.assertEquals('Test', result.mode);
        System.assertEquals('RE1', result.reportId);
        System.assertEquals(3, result.statusCode);
        System.assertEquals(4, result.columns.size());
        System.assertEquals(4, result.columnTypes.size());
        System.assertEquals(3, result.rows.size());
        System.assertEquals(1, result.pagesFetched);
        System.assertEquals(1, result.batches.size());
        System.assertEquals('407', result.batches[0].batchId);
        System.assertEquals(3, result.batches[0].transactionCount);
        // 266,40 + 2.200,00 - 20,00 = 2446.40 (not 26640 + 220000 - 2000)
        System.assertEquals(2446.40, result.batches[0].netAmount);

        String runBody = mock.requestBodies[0];
        System.assert(runBody.contains('<paramValue>2026-07-01 00:00:00</paramValue>'), runBody);
        System.assert(runBody.contains('<paramValue>2026-07-01 23:59:59</paramValue>'), runBody);
        System.assert(runBody.contains('<paramValue>Settled</paramValue>'), runBody);
        System.assert(runBody.contains('<password>p&amp;ss</password>'), runBody);
    }

    @IsTest
    static void runningReportCanBeCheckedAgain() {
        Test.setMock(HttpCalloutMock.class, new ReportingMock('2'));

        Test.startTest();
        PayflowReportController.ReportResult pending = PayflowReportController.runReport(
            'TransactionSummaryReport', '2026-07-01', '2026-07-02', null, null, null, null
        );
        PayflowReportController.ReportResult done = PayflowReportController.checkReport(pending.reportId, 1);
        Test.stopTest();

        System.assertEquals(2, pending.statusCode);
        System.assertEquals(0, pending.rows.size());
        System.assertEquals(3, done.statusCode);
        System.assertEquals(3, done.rows.size());
    }

    @IsTest
    static void payflowErrorIsReturnedToUser() {
        ReportingMock mock = new ReportingMock('3');
        mock.baseOverride = '<baseResponse><responseCode>101</responseCode><responseMsg>Authentication failed</responseMsg></baseResponse>';
        Test.setMock(HttpCalloutMock.class, mock);

        String message;
        Test.startTest();
        try {
            PayflowReportController.runReport('SettlementReport', '2026-07-01', '2026-07-01', 'Settled', null, 50, 1);
        } catch (AuraHandledException e) {
            message = e.getMessage();
        }
        Test.stopTest();

        System.assert(message != null && message.contains('Authentication failed'), message);
    }

    @IsTest
    static void invalidInputIsRejected() {
        String badReport;
        String badRange;
        try {
            PayflowReportController.runReport('OtherReport', '2026-07-01', '2026-07-01', null, null, null, null);
        } catch (AuraHandledException e) {
            badReport = e.getMessage();
        }
        try {
            PayflowReportController.runReport('SettlementReport', '2026-07-05', '2026-07-01', null, null, null, null);
        } catch (AuraHandledException e) {
            badRange = e.getMessage();
        }

        System.assert(badReport != null && badReport.contains('Unsupported report'), badReport);
        System.assert(badRange != null && badRange.contains('End date'), badRange);
    }

    @IsTest
    static void batchIdReportSendsProcessorWithoutSettlementStatus() {
        ReportingMock mock = new ReportingMock('3');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        PayflowReportController.runReport('BatchIDReport', '2026-07-01', '2026-07-01', 'Settled', null, 50, 1);
        Test.stopTest();

        String runBody = mock.requestBodies[0];
        System.assert(runBody.contains('<reportName>BatchIDReport</reportName>'), runBody);
        System.assert(runBody.contains('<paramName>processor</paramName>'), runBody);
        System.assert(!runBody.contains('settlement_status'), runBody);
    }

    @IsTest
    static void templateRunsByTemplateNameWithOptionalDates() {
        ReportingMock mock = new ReportingMock('3');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        PayflowReportController.ReportResult saved = PayflowReportController.runTemplate(
            ' IAFC Settlement ', null, null, null, null, 1
        );
        PayflowReportController.runTemplate('IAFC Settlement', '2026-07-01', '2026-07-02', 'GMT-05:00', 50, 1);
        Test.stopTest();

        System.assertEquals(3, saved.rows.size());
        String savedBody = mock.requestBodies[0];
        System.assert(savedBody.contains('<templateName>IAFC Settlement</templateName>'), savedBody);
        System.assert(!savedBody.contains('<reportName>'), savedBody);
        System.assert(!savedBody.contains('start_date'), savedBody);

        String overrideBody = mock.requestBodies[3];
        System.assert(overrideBody.contains('<paramValue>2026-07-01 00:00:00</paramValue>'), overrideBody);
        System.assert(overrideBody.contains('<paramValue>GMT-05:00</paramValue>'), overrideBody);
    }

    @IsTest
    static void scheduledRunsAreListedNewestFirstAndLoadable() {
        ReportingMock mock = new ReportingMock('3');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        List<PayflowReportController.ScheduledRun> runs = PayflowReportController.findScheduledReports(
            'Daily Settlement', '2026-10-01', '2026-10-02'
        );
        PayflowReportController.ReportResult loaded = PayflowReportController.checkReport(runs[0].reportId, 1);
        Test.stopTest();

        System.assertEquals(2, runs.size());
        System.assertEquals('RE_NEW', runs[0].reportId);
        System.assertEquals('RE_OLD', runs[1].reportId);
        System.assertEquals(3, runs[0].statusCode);

        String scheduleBody = mock.requestBodies[0];
        System.assert(scheduleBody.contains('<scheduleName>Daily Settlement</scheduleName>'), scheduleBody);
        System.assert(scheduleBody.contains('<startDate>2026-10-01</startDate>'), scheduleBody);
        System.assertEquals(3, loaded.statusCode);
        System.assertEquals(3, loaded.rows.size());
    }

    @IsTest
    static void namesAreRequired() {
        String template;
        String schedule;
        String reportId;
        try {
            PayflowReportController.runTemplate('  ', null, null, null, null, null);
        } catch (AuraHandledException e) {
            template = e.getMessage();
        }
        try {
            PayflowReportController.findScheduledReports(null, '2026-10-01', '2026-10-02');
        } catch (AuraHandledException e) {
            schedule = e.getMessage();
        }
        try {
            PayflowReportController.checkReport('', 1);
        } catch (AuraHandledException e) {
            reportId = e.getMessage();
        }

        System.assert(template != null && template.contains('Template name is required'), template);
        System.assert(schedule != null && schedule.contains('Schedule name is required'), schedule);
        System.assert(reportId != null && reportId.contains('Report Id is required'), reportId);
    }
}