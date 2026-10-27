/**
 * SHOWCYCLE-1441 - Runs Payflow Reporting API reports (run -> metadata -> data pages)
 * using Payflow credentials from the packaged List Custom Setting s7e__Payment_Setting__c.
 *
 * Unpackaged / subscriber-only utility (not shipped in the managed package).
 * Deploy manually to a subscriber org. Queries intentionally skip WITH SECURITY_ENFORCED /
 * FLS checks so it can run for the limited users who are given Apex + tab access.
 */
public without sharing class PayflowReportController {

    private static final String LIVE_ENDPOINT = 'https://payments-reports.paypal.com/reportingengine';
    private static final String TEST_ENDPOINT = 'https://payments-reports.paypal.com/test-reportingengine';
    private static final Set<String> REPORT_NAMES = new Set<String>{ 'SettlementReport', 'TransactionSummaryReport', 'BatchIDReport' };
    private static final Set<String> PROCESSOR_REPORTS = new Set<String>{ 'SettlementReport', 'BatchIDReport' };
    private static final Set<String> SETTLEMENT_STATUSES = new Set<String>{ 'Settled', 'Unsettled', 'All' };
    private static final Integer MAX_PAGE_SIZE = 50;
    private static final Integer MAX_PAGES = 10;
    private static final Integer MAX_NAME_LENGTH = 100;
    private static final Integer CALLOUT_TIMEOUT_MS = 60000;
    private static final String STATUS_COMPLETE = '3';

    public class PayflowReportException extends Exception {}

    public class ReportResult {
        @AuraEnabled public String mode;
        @AuraEnabled public String reportId;
        @AuraEnabled public Integer statusCode;
        @AuraEnabled public String statusMsg;
        @AuraEnabled public Integer totalRows = 0;
        @AuraEnabled public Integer totalPages = 0;
        @AuraEnabled public Integer pagesFetched = 0;
        @AuraEnabled public List<String> columns = new List<String>();
        @AuraEnabled public List<String> columnTypes = new List<String>();
        @AuraEnabled public List<List<String>> rows = new List<List<String>>();
        @AuraEnabled public List<BatchSummary> batches = new List<BatchSummary>();
    }

    public class BatchSummary {
        @AuraEnabled public String batchId;
        @AuraEnabled public Integer transactionCount = 0;
        @AuraEnabled public Decimal netAmount = 0;
    }

    public class ScheduledRun {
        @AuraEnabled public String reportId;
        @AuraEnabled public Integer statusCode;
        @AuraEnabled public String statusMsg;
        @AuraEnabled public String executionTime;
    }

    private class Credentials {
        Boolean isLive;
        String endpoint;
        String user;
        String vendor;
        String partner;
        String password;
    }

    /** Runs a standard report by report name, using the date range and filters given. */
    @AuraEnabled
    public static ReportResult runReport(
        String reportName,
        String startDate,
        String endDate,
        String settlementStatus,
        String timezone,
        Integer pageSize,
        Integer maxPages
    ) {
        try {
            if (!REPORT_NAMES.contains(reportName)) {
                throw new PayflowReportException('Unsupported report: ' + reportName);
            }
            Map<String, String> params = dateRangeParams(startDate, endDate, true);
            if (PROCESSOR_REPORTS.contains(reportName)) {
                params.put('processor', 'PayPal');
            }
            if (reportName == 'SettlementReport') {
                String status = String.isBlank(settlementStatus) ? 'Settled' : settlementStatus;
                if (!SETTLEMENT_STATUSES.contains(status)) {
                    throw new PayflowReportException('Unsupported settlement status: ' + status);
                }
                params.put('settlement_status', status);
            }
            addTimezone(params, timezone);
            return execute(tag('reportName', reportName), params, pageSize, maxPages);
        } catch (Exception e) {
            throw toAuraException(e);
        }
    }

    /**
     * Runs a report template saved in PayPal Manager. Its saved parameters are used;
     * dates and timezone, when given, override them.
     */
    @AuraEnabled
    public static ReportResult runTemplate(
        String templateName,
        String startDate,
        String endDate,
        String timezone,
        Integer pageSize,
        Integer maxPages
    ) {
        try {
            String name = requireName(templateName, 'Template name');
            Map<String, String> params = dateRangeParams(startDate, endDate, false);
            addTimezone(params, timezone);
            return execute(tag('templateName', name), params, pageSize, maxPages);
        } catch (Exception e) {
            throw toAuraException(e);
        }
    }

    /** Lists the reports a PayPal Manager schedule has already produced within the date range, newest first. */
    @AuraEnabled
    public static List<ScheduledRun> findScheduledReports(String scheduleName, String startDate, String endDate) {
        try {
            String name = requireName(scheduleName, 'Schedule name');
            Date startDay = parseDate(startDate, 'Start date');
            Date endDay = parseDate(endDate, 'End date');
            if (endDay < startDay) {
                throw new PayflowReportException('End date must be on or after start date.');
            }

            Dom.XmlNode root = send(loadCredentials(), 'getResultsRequest',
                tag('scheduleName', name) + tag('startDate', formatDay(startDay)) + tag('endDate', formatDay(endDay))
            );
            Dom.XmlNode response = root.getChildElement('getResultsResponse', null);

            List<ScheduledRun> runs = new List<ScheduledRun>();
            if (response != null) {
                for (Dom.XmlNode node : response.getChildElements()) {
                    if (node.getName() != 'Results') {
                        continue;
                    }
                    ScheduledRun run = new ScheduledRun();
                    run.reportId = childText(node, 'reportId');
                    run.statusCode = toInteger(childText(node, 'statusCode'));
                    run.statusMsg = childText(node, 'statusMsg');
                    run.executionTime = childText(node, 'executionTime');
                    runs.add(run);
                }
            }
            sortNewestFirst(runs);
            return runs;
        } catch (Exception e) {
            throw toAuraException(e);
        }
    }

    /**
     * Loads an existing report by Report ID: one still running (statusCode 2),
     * one produced by a schedule, or one from an earlier run.
     */
    @AuraEnabled
    public static ReportResult checkReport(String reportId, Integer maxPages) {
        try {
            String id = requireName(reportId, 'Report Id');
            Credentials creds = loadCredentials();
            Dom.XmlNode root = send(creds, 'getResultsRequest', tag('reportId', id));

            Dom.XmlNode response = root.getChildElement('getResultsResponse', null);
            Dom.XmlNode results = response != null ? response.getChildElement('Results', null) : null;
            ReportResult result = readStatus(results != null ? results : response);
            result.mode = creds.isLive ? 'Live' : 'Test';
            if (String.isBlank(result.reportId)) {
                result.reportId = id;
            }
            if (String.valueOf(result.statusCode) == STATUS_COMPLETE) {
                fetchData(creds, result, clamp(maxPages, 3, MAX_PAGES));
            }
            return result;
        } catch (Exception e) {
            throw toAuraException(e);
        }
    }

    private static ReportResult execute(String reportSelector, Map<String, String> params, Integer pageSize, Integer maxPages) {
        String paramXml = '';
        for (String name : params.keySet()) {
            paramXml += '<reportParam>' + tag('paramName', name) + tag('paramValue', params.get(name)) + '</reportParam>';
        }

        Credentials creds = loadCredentials();
        Dom.XmlNode root = send(creds, 'runReportRequest',
            reportSelector + paramXml + tag('pageSize', String.valueOf(clamp(pageSize, MAX_PAGE_SIZE, MAX_PAGE_SIZE)))
        );

        ReportResult result = readStatus(root.getChildElement('runReportResponse', null));
        result.mode = creds.isLive ? 'Live' : 'Test';
        if (String.valueOf(result.statusCode) == STATUS_COMPLETE) {
            fetchData(creds, result, clamp(maxPages, 3, MAX_PAGES));
        }
        return result;
    }

    private static Map<String, String> dateRangeParams(String startDate, String endDate, Boolean required) {
        Map<String, String> params = new Map<String, String>();
        if (!required && String.isBlank(startDate) && String.isBlank(endDate)) {
            return params;
        }
        Date startDay = parseDate(startDate, 'Start date');
        Date endDay = parseDate(endDate, 'End date');
        if (endDay < startDay) {
            throw new PayflowReportException('End date must be on or after start date.');
        }
        params.put('start_date', formatDay(startDay) + ' 00:00:00');
        params.put('end_date', formatDay(endDay) + ' 23:59:59');
        return params;
    }

    private static void addTimezone(Map<String, String> params, String timezone) {
        if (String.isNotBlank(timezone)) {
            params.put('timezone', timezone.trim());
        }
    }

    private static String requireName(String value, String label) {
        if (String.isBlank(value)) {
            throw new PayflowReportException(label + ' is required.');
        }
        String trimmed = value.trim();
        if (trimmed.length() > MAX_NAME_LENGTH) {
            throw new PayflowReportException(label + ' must be ' + MAX_NAME_LENGTH + ' characters or fewer.');
        }
        return trimmed;
    }

    private static void sortNewestFirst(List<ScheduledRun> runs) {
        for (Integer i = 1; i < runs.size(); i++) {
            ScheduledRun current = runs[i];
            Integer j = i - 1;
            while (j >= 0 && (runs[j].executionTime == null ? '' : runs[j].executionTime)
                    < (current.executionTime == null ? '' : current.executionTime)) {
                runs[j + 1] = runs[j];
                j--;
            }
            runs[j + 1] = current;
        }
    }

    private static void fetchData(Credentials creds, ReportResult result, Integer maxPages) {
        Dom.XmlNode meta = send(creds, 'getMetaDataRequest', tag('reportId', result.reportId))
            .getChildElement('getMetaDataResponse', null);
        if (meta == null) {
            throw new PayflowReportException('Payflow returned no report metadata.');
        }

        for (Dom.XmlNode node : meta.getChildElements()) {
            String name = node.getName();
            if (name == 'numberOfRows') {
                result.totalRows = toInteger(node.getText());
            } else if (name == 'numberOfPages') {
                result.totalPages = toInteger(node.getText());
            } else if (name == 'columnMetaData') {
                Dom.XmlNode dataName = node.getChildElement('dataName', null);
                Dom.XmlNode dataType = node.getChildElement('dataType', null);
                result.columns.add(dataName != null ? dataName.getText() : 'Column ' + node.getAttribute('colNum', null));
                result.columnTypes.add(dataType != null ? dataType.getText() : 'string');
            }
        }

        Integer pagesToFetch = Math.min(result.totalPages, maxPages);
        for (Integer pageNum = 1; pageNum <= pagesToFetch; pageNum++) {
            Dom.XmlNode data = send(creds, 'getDataRequest',
                tag('reportId', result.reportId) + tag('pageNum', String.valueOf(pageNum))
            ).getChildElement('getDataResponse', null);
            if (data == null) {
                continue;
            }
            for (Dom.XmlNode rowNode : data.getChildElements()) {
                if (rowNode.getName() != 'reportDataRow') {
                    continue;
                }
                List<String> cells = new List<String>();
                for (Dom.XmlNode cell : rowNode.getChildElements()) {
                    if (cell.getName() == 'columnData') {
                        Dom.XmlNode value = cell.getChildElement('data', null);
                        cells.add(value != null ? value.getText() : '');
                    }
                }
                result.rows.add(cells);
            }
            result.pagesFetched = pageNum;
        }

        result.batches = summarizeBatches(result.columns, result.rows);
    }

    private static List<BatchSummary> summarizeBatches(List<String> columns, List<List<String>> rows) {
        Integer batchIdx = columns.indexOf('Batch ID');
        Integer amountIdx = columns.indexOf('Amount');
        Integer typeIdx = columns.indexOf('Type');
        Map<String, BatchSummary> byBatch = new Map<String, BatchSummary>();
        if (batchIdx < 0 || amountIdx < 0) {
            return byBatch.values();
        }

        for (List<String> row : rows) {
            String batchId = batchIdx < row.size() ? row[batchIdx] : null;
            if (String.isBlank(batchId)) {
                continue;
            }
            BatchSummary summary = byBatch.get(batchId);
            if (summary == null) {
                summary = new BatchSummary();
                summary.batchId = batchId;
                byBatch.put(batchId, summary);
            }
            summary.transactionCount++;

            Decimal amount = amountIdx >= 0 && amountIdx < row.size() ? toDecimal(row[amountIdx]) : 0;
            Boolean isCredit = typeIdx >= 0 && typeIdx < row.size() && row[typeIdx] == 'Credit';
            summary.netAmount += isCredit ? -amount : amount;
        }
        return byBatch.values();
    }

    private static Credentials loadCredentials() {
        // Subscriber org: packaged List Custom Setting (public). No FLS / sharing enforcement.
        List<s7e__Payment_Setting__c> settings = [
            SELECT s7e__Live_Mode__c, s7e__Username__c, s7e__Password__c, s7e__Vendor__c, s7e__Partner__c,
                   s7e__Test_Mode_Username__c, s7e__Test_Mode_Password__c, s7e__Test_Mode_Vendor__c, s7e__Test_Mode_Partner__c
            FROM s7e__Payment_Setting__c
            LIMIT 1
        ];
        if (settings.isEmpty()) {
            throw new PayflowReportException('Payment Setting with Payflow credentials was not found.');
        }

        s7e__Payment_Setting__c setting = settings[0];
        Credentials creds = new Credentials();
        creds.isLive = setting.s7e__Live_Mode__c == true;
        creds.endpoint = creds.isLive ? LIVE_ENDPOINT : TEST_ENDPOINT;
        creds.user = creds.isLive ? setting.s7e__Username__c : setting.s7e__Test_Mode_Username__c;
        creds.vendor = creds.isLive ? setting.s7e__Vendor__c : setting.s7e__Test_Mode_Vendor__c;
        creds.partner = creds.isLive ? setting.s7e__Partner__c : setting.s7e__Test_Mode_Partner__c;
        creds.password = creds.isLive ? setting.s7e__Password__c : setting.s7e__Test_Mode_Password__c;
        if (String.isBlank(creds.user) || String.isBlank(creds.vendor) || String.isBlank(creds.password)) {
            throw new PayflowReportException(
                'Payflow ' + (creds.isLive ? 'live' : 'test') + ' credentials are incomplete in Payment Setting.'
            );
        }
        return creds;
    }

    private static Dom.XmlNode send(Credentials creds, String requestTag, String innerXml) {
        String body = '<?xml version="1.0" encoding="UTF-8"?><reportingEngineRequest>'
            + '<authRequest>'
            + tag('user', creds.user) + tag('vendor', creds.vendor)
            + tag('partner', creds.partner) + tag('password', creds.password)
            + '</authRequest>'
            + '<' + requestTag + '>' + innerXml + '</' + requestTag + '>'
            + '</reportingEngineRequest>';

        HttpRequest req = new HttpRequest();
        req.setEndpoint(creds.endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'text/plain');
        req.setTimeout(CALLOUT_TIMEOUT_MS);
        req.setBody(body);

        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200) {
            throw new PayflowReportException('Payflow Reporting HTTP error ' + res.getStatusCode() + ' ' + res.getStatus());
        }

        Dom.XmlNode root = res.getBodyDocument().getRootElement();
        Dom.XmlNode base = root.getChildElement('baseResponse', null);
        String code = base != null ? childText(base, 'responseCode') : null;
        if (code != '100') {
            throw new PayflowReportException('Payflow error ' + code + ': ' + (base != null ? childText(base, 'responseMsg') : 'No response'));
        }
        return root;
    }

    private static ReportResult readStatus(Dom.XmlNode node) {
        if (node == null) {
            throw new PayflowReportException('Payflow returned no report status.');
        }
        ReportResult result = new ReportResult();
        result.reportId = childText(node, 'reportId');
        result.statusCode = toInteger(childText(node, 'statusCode'));
        result.statusMsg = childText(node, 'statusMsg');
        return result;
    }

    private static String childText(Dom.XmlNode parent, String name) {
        Dom.XmlNode child = parent.getChildElement(name, null);
        return child != null ? child.getText() : null;
    }

    private static String tag(String name, String value) {
        return '<' + name + '>' + (value == null ? '' : value.escapeXml()) + '</' + name + '>';
    }

    private static Date parseDate(String value, String label) {
        if (String.isBlank(value)) {
            throw new PayflowReportException(label + ' is required.');
        }
        try {
            return Date.valueOf(value);
        } catch (Exception e) {
            throw new PayflowReportException(label + ' must be in YYYY-MM-DD format.');
        }
    }

    private static String formatDay(Date d) {
        return Datetime.newInstanceGmt(d, Time.newInstance(0, 0, 0, 0)).formatGmt('yyyy-MM-dd');
    }

    private static Integer clamp(Integer value, Integer defaultValue, Integer maxValue) {
        if (value == null || value < 1) {
            return defaultValue;
        }
        return Math.min(value, maxValue);
    }

    private static Integer toInteger(String value) {
        try {
            return String.isBlank(value) ? 0 : Integer.valueOf(value.trim());
        } catch (Exception e) {
            return 0;
        }
    }

    /**
     * Parse Payflow currency text. Supports US (2,200.00 / 266.40) and
     * European (2.200,00 / 266,40). Uses the last separator as the decimal mark.
     */
    private static Decimal toDecimal(String value) {
        try {
            if (String.isBlank(value)) {
                return 0;
            }
            String text = value.trim();
            Integer lastComma = text.lastIndexOf(',');
            Integer lastDot = text.lastIndexOf('.');
            if (lastComma > lastDot) {
                // European: 266,40 or 2.200,00
                text = text.replace('.', '').replace(',', '.');
            } else {
                // US / plain: 2,200.00 or 266.40 or 520
                text = text.replace(',', '');
            }
            return Decimal.valueOf(text);
        } catch (Exception e) {
            return 0;
        }
    }

    private static AuraHandledException toAuraException(Exception e) {
        AuraHandledException ex = new AuraHandledException(e.getMessage());
        ex.setMessage(e.getMessage());
        return ex;
    }
}