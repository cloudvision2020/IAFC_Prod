import { LightningElement } from 'lwc';
import runReport from '@salesforce/apex/PayflowReportController.runReport';
import checkReport from '@salesforce/apex/PayflowReportController.checkReport';
import runTemplate from '@salesforce/apex/PayflowReportController.runTemplate';
import findScheduledReports from '@salesforce/apex/PayflowReportController.findScheduledReports';

const RUN_BY_REPORT = 'report';
const RUN_BY_TEMPLATE = 'template';
const RUN_BY_SCHEDULE = 'schedule';
const RUN_BY_REPORT_ID = 'reportId';

const PRIMARY_ACTIONS = {
    [RUN_BY_REPORT]: { label: 'Run Report', icon: 'utility:play' },
    [RUN_BY_TEMPLATE]: { label: 'Run Template', icon: 'utility:play' },
    [RUN_BY_SCHEDULE]: { label: 'Find Scheduled Reports', icon: 'utility:search' },
    [RUN_BY_REPORT_ID]: { label: 'Load Report', icon: 'utility:download' }
};

const SCHEDULED_COLUMNS = [
    { label: 'Executed', fieldName: 'executionTime' },
    { label: 'Report Id', fieldName: 'reportId' },
    { label: 'Status', fieldName: 'statusMsg' },
    {
        type: 'button',
        initialWidth: 110,
        typeAttributes: { label: 'Load', name: 'load', variant: 'brand-outline', iconName: 'utility:download' }
    }
];

const STATUS_RUNNING = 2;
const STATUS_COMPLETE = 3;
const SCROLL_ROW_THRESHOLD = 12;
const FORMULA_PREFIX = /^[=+\-@\t\r]/;

const BATCH_COLUMNS = [
    { label: 'Batch ID', fieldName: 'batchId' },
    { label: 'Transactions', fieldName: 'transactionCount', type: 'number' },
    {
        label: 'Net Amount (Sales - Credits)',
        fieldName: 'netAmount',
        type: 'number',
        typeAttributes: { minimumFractionDigits: 2, maximumFractionDigits: 2 }
    }
];

function toIsoDate(date) {
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${date.getFullYear()}-${month}-${day}`;
}

/**
 * Parse Payflow currency text. Supports US (2,200.00 / 266.40) and
 * European (2.200,00 / 266,40). Uses the last separator as the decimal mark.
 * Example: 266,40 -> 266.4 (NOT 26640).
 */
function toNumber(value) {
    if (value === null || value === undefined || value === '') {
        return null;
    }
    let text = String(value).trim();
    if (!text) {
        return null;
    }
    const lastComma = text.lastIndexOf(',');
    const lastDot = text.lastIndexOf('.');
    if (lastComma > lastDot) {
        // European: 266,40 or 2.200,00
        text = text.replace(/\./g, '').replace(',', '.');
    } else {
        // US / plain: 2,200.00 or 266.40 or 520
        text = text.replace(/,/g, '');
    }
    const parsed = Number(text);
    return Number.isNaN(parsed) ? null : parsed;
}

/** Format a parsed amount with a fixed decimal point and 2 places (266.40). */
function formatAmount(value) {
    const amount = toNumber(value);
    if (amount === null) {
        return value === null || value === undefined ? '' : String(value);
    }
    const negative = amount < 0;
    const absolute = Math.abs(amount);
    const fixed = absolute.toFixed(2);
    const [whole, fraction] = fixed.split('.');
    const withGroups = whole.replace(/\B(?=(\d{3})+(?!\d))/g, ',');
    return `${negative ? '-' : ''}${withGroups}.${fraction}`;
}

function escapeCsv(value) {
    let text = value === null || value === undefined ? '' : String(value);
    if (FORMULA_PREFIX.test(text) && toNumber(text) === null) {
        text = `'${text}`;
    }
    return /[",\r\n]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
}

function escapeHtml(value) {
    return (value === null || value === undefined ? '' : String(value))
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
}

export default class PayflowReportViewer extends LightningElement {
    runBy = RUN_BY_REPORT;
    reportName = 'SettlementReport';
    templateName = '';
    scheduleName = '';
    reportId = '';
    startDate;
    endDate;
    settlementStatus = 'Settled';
    timezone = '';
    pageSize = 50;
    maxPages = 3;

    result;
    resultSource;
    scheduledRuns;
    errorMessage;
    isLoading = false;

    tableColumns = [];
    tableData = [];
    sortedBy;
    sortedDirection = 'asc';

    batchColumns = BATCH_COLUMNS;
    scheduledColumns = SCHEDULED_COLUMNS;

    runByOptions = [
        { label: 'Standard Report', value: RUN_BY_REPORT },
        { label: 'Saved Template', value: RUN_BY_TEMPLATE },
        { label: 'Scheduled Report', value: RUN_BY_SCHEDULE },
        { label: 'Report Id', value: RUN_BY_REPORT_ID }
    ];

    reportOptions = [
        { label: 'Settlement Report', value: 'SettlementReport' },
        { label: 'Transaction Summary Report', value: 'TransactionSummaryReport' },
        { label: 'Batch ID Report (totals per batch)', value: 'BatchIDReport' }
    ];

    settlementOptions = [
        { label: 'Settled', value: 'Settled' },
        { label: 'Unsettled', value: 'Unsettled' },
        { label: 'All', value: 'All' }
    ];

    connectedCallback() {
        const yesterday = new Date();
        yesterday.setDate(yesterday.getDate() - 1);
        this.startDate = toIsoDate(yesterday);
        this.endDate = this.startDate;
    }

    get isReportMode() {
        return this.runBy === RUN_BY_REPORT;
    }

    get isTemplateMode() {
        return this.runBy === RUN_BY_TEMPLATE;
    }

    get isScheduleMode() {
        return this.runBy === RUN_BY_SCHEDULE;
    }

    get isReportIdMode() {
        return this.runBy === RUN_BY_REPORT_ID;
    }

    get isSettlementReport() {
        return this.isReportMode && this.reportName === 'SettlementReport';
    }

    get isSettlementDisabled() {
        return !this.isSettlementReport;
    }

    get areDatesRequired() {
        return this.isReportMode || this.isScheduleMode;
    }

    get areDatesDisabled() {
        return this.isReportIdMode;
    }

    get isRunOptionDisabled() {
        return this.isScheduleMode || this.isReportIdMode;
    }

    get dateHelp() {
        if (this.isTemplateMode) {
            return 'Optional. Leave both blank to use the dates saved in the template.';
        }
        if (this.isScheduleMode) {
            return 'Lists scheduled reports that ran between these dates.';
        }
        return undefined;
    }

    get primaryLabel() {
        return PRIMARY_ACTIONS[this.runBy].label;
    }

    get primaryIcon() {
        return PRIMARY_ACTIONS[this.runBy].icon;
    }

    get hasScheduledRuns() {
        return this.scheduledRuns?.length > 0;
    }

    get scheduledRunCount() {
        return this.scheduledRuns?.length || 0;
    }

    get sourceLabel() {
        return this.resultSource || '';
    }

    get isRunning() {
        return this.result?.statusCode === STATUS_RUNNING;
    }

    get isComplete() {
        return this.result?.statusCode === STATUS_COMPLETE;
    }

    get hasRows() {
        return this.tableData.length > 0;
    }

    get hasBatches() {
        return this.result?.batches?.length > 0;
    }

    get rowCount() {
        return this.tableData.length;
    }

    get columnCount() {
        return this.result?.columns?.length || 0;
    }

    get tableContainerClass() {
        return this.tableData.length > SCROLL_ROW_THRESHOLD
            ? 'table-container table-container_scroll'
            : 'table-container';
    }

    handleRunByChange(event) {
        this.runBy = event.detail.value;
        this.scheduledRuns = undefined;
        this.errorMessage = undefined;
        this.applyResult(undefined);
    }

    handleReportChange(event) {
        this.reportName = event.detail.value;
    }

    handleTemplateChange(event) {
        this.templateName = event.detail.value;
    }

    handleScheduleChange(event) {
        this.scheduleName = event.detail.value;
    }

    handleReportIdChange(event) {
        this.reportId = event.detail.value;
    }

    handleStartChange(event) {
        this.startDate = event.detail.value;
    }

    handleEndChange(event) {
        this.endDate = event.detail.value;
    }

    handleSettlementChange(event) {
        this.settlementStatus = event.detail.value;
    }

    handleTimezoneChange(event) {
        this.timezone = event.detail.value;
    }

    handlePageSizeChange(event) {
        this.pageSize = event.detail.value;
    }

    handleMaxPagesChange(event) {
        this.maxPages = event.detail.value;
    }

    async handlePrimary() {
        if (!this.validateInputs()) {
            return;
        }
        if (this.isScheduleMode) {
            await this.loadScheduledRuns();
            return;
        }

        this.scheduledRuns = undefined;
        if (this.isTemplateMode) {
            const name = this.templateName.trim();
            await this.callApex(
                () =>
                    runTemplate({
                        templateName: name,
                        startDate: this.startDate || null,
                        endDate: this.endDate || null,
                        timezone: this.timezone,
                        pageSize: Number(this.pageSize),
                        maxPages: Number(this.maxPages)
                    }),
                `Template: ${name}`
            );
        } else if (this.isReportIdMode) {
            await this.loadReportById(this.reportId.trim(), `Report Id: ${this.reportId.trim()}`);
        } else {
            const label = this.reportOptions.find((option) => option.value === this.reportName)?.label;
            await this.callApex(
                () =>
                    runReport({
                        reportName: this.reportName,
                        startDate: this.startDate,
                        endDate: this.endDate,
                        settlementStatus: this.isSettlementReport ? this.settlementStatus : null,
                        timezone: this.timezone,
                        pageSize: Number(this.pageSize),
                        maxPages: Number(this.maxPages)
                    }),
                label
            );
        }
    }

    async handleCheck() {
        await this.loadReportById(this.result.reportId, this.resultSource);
    }

    handleScheduledRowAction(event) {
        const run = event.detail.row;
        this.loadReportById(run.reportId, `Schedule: ${this.scheduleName.trim()} (${run.executionTime || run.reportId})`);
    }

    async loadScheduledRuns() {
        this.isLoading = true;
        this.errorMessage = undefined;
        this.applyResult(undefined);
        try {
            this.scheduledRuns = await findScheduledReports({
                scheduleName: this.scheduleName.trim(),
                startDate: this.startDate,
                endDate: this.endDate
            });
        } catch (error) {
            this.scheduledRuns = undefined;
            this.errorMessage = this.toMessage(error);
        } finally {
            this.isLoading = false;
        }
    }

    async loadReportById(reportId, source) {
        await this.callApex(() => checkReport({ reportId, maxPages: Number(this.maxPages) }), source);
    }

    async callApex(apexCall, source) {
        this.isLoading = true;
        this.errorMessage = undefined;
        try {
            this.applyResult(await apexCall(), source);
        } catch (error) {
            this.applyResult(undefined);
            this.errorMessage = this.toMessage(error);
        } finally {
            this.isLoading = false;
        }
    }

    toMessage(error) {
        return error?.body?.message || error?.message || 'Payflow report request failed.';
    }

    applyResult(result, source) {
        this.result = result;
        this.resultSource = result ? source : undefined;
        this.sortedBy = undefined;
        this.sortedDirection = 'asc';

        const columns = result?.columns || [];
        const types = result?.columnTypes || [];
        // Currency: parse Payflow text (US or European), then show as 1,234.56 style decimals.
        this.tableColumns = columns.map((label, index) => this.buildColumn(label, types[index], index));
        this.tableData = (result?.rows || []).map((cells, rowIndex) => {
            const row = { rowKey: String(rowIndex) };
            columns.forEach((label, index) => {
                const value = index < cells.length ? cells[index] : '';
                if (types[index] === 'currency') {
                    row[`c${index}`] = formatAmount(value);
                    row[`n${index}`] = toNumber(value);
                } else {
                    row[`c${index}`] = value;
                    row[`n${index}`] = null;
                }
            });
            return row;
        });
    }

    buildColumn(label, dataType, index) {
        const column = {
            label,
            fieldName: `c${index}`,
            sortable: true,
            initialWidth: Math.min(Math.max(label.length * 9 + 48, 120), 280),
            wrapText: false
        };
        if (dataType === 'currency') {
            column.cellAttributes = { alignment: 'right' };
        }
        return column;
    }

    handleSort(event) {
        const { fieldName, sortDirection } = event.detail;
        const direction = sortDirection === 'asc' ? 1 : -1;
        const numericField = fieldName?.startsWith('c') ? `n${fieldName.slice(1)}` : null;
        this.tableData = [...this.tableData].sort((a, b) => {
            const leftNum = numericField ? a[numericField] : null;
            const rightNum = numericField ? b[numericField] : null;
            if (leftNum !== null && leftNum !== undefined && rightNum !== null && rightNum !== undefined) {
                if (leftNum === rightNum) {
                    return 0;
                }
                return (leftNum - rightNum) * direction;
            }
            const left = a[fieldName];
            const right = b[fieldName];
            if (left === right) {
                return 0;
            }
            if (left === null || left === undefined || left === '') {
                return 1;
            }
            if (right === null || right === undefined || right === '') {
                return -1;
            }
            return String(left).localeCompare(String(right), undefined, { numeric: true }) * direction;
        });
        this.sortedBy = fieldName;
        this.sortedDirection = sortDirection;
    }

    handleDownload(event) {
        if (event.detail.value === 'excel') {
            this.downloadFile(this.buildExcel(), 'xls', 'application/vnd.ms-excel');
        } else {
            this.downloadFile(this.buildCsv(), 'csv', 'text/csv');
        }
    }

    buildCsv() {
        const columns = this.result.columns;
        const lines = [columns.map(escapeCsv).join(',')];
        this.result.rows.forEach((cells) => {
            lines.push(columns.map((label, index) => escapeCsv(cells[index])).join(','));
        });
        return '\uFEFF' + lines.join('\r\n');
    }

    buildExcel() {
        const columns = this.result.columns;
        const types = this.result.columnTypes || [];
        const header = columns.map((label) => `<th>${escapeHtml(label)}</th>`).join('');
        const body = this.result.rows
            .map((cells) => {
                const tds = columns
                    .map((label, index) => {
                        const value = cells[index];
                        if (types[index] === 'currency' && toNumber(value) !== null) {
                            return `<td class="num">${toNumber(value)}</td>`;
                        }
                        return `<td class="text">${escapeHtml(value)}</td>`;
                    })
                    .join('');
                return `<tr>${tds}</tr>`;
            })
            .join('');

        const batchRows = (this.result.batches || [])
            .map(
                (b) =>
                    `<tr><td class="text">${escapeHtml(b.batchId)}</td><td>${b.transactionCount}</td>` +
                    `<td class="num">${b.netAmount}</td></tr>`
            )
            .join('');
        const batchTable = batchRows
            ? '<h3>Batch Summary</h3><table border="1"><tr><th>Batch ID</th><th>Transactions</th>' +
              `<th>Net Amount (Sales - Credits)</th></tr>${batchRows}</table><br/>`
            : '';

        return (
            '<html xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:x="urn:schemas-microsoft-com:office:excel">' +
            '<head><meta charset="UTF-8"/><style>' +
            '.text{mso-number-format:"\\@";} .num{mso-number-format:"0.00";} th{background:#f3f3f3;}' +
            '</style></head><body>' +
            `<h3>${escapeHtml(this.resultSource)} - Report Id ${escapeHtml(this.result.reportId)}</h3>` +
            batchTable +
            `<h3>Transactions</h3><table border="1"><tr>${header}</tr>${body}</table>` +
            '</body></html>'
        );
    }

    downloadFile(content, extension, mimeType) {
        const link = document.createElement('a');
        link.href = `data:${mimeType};charset=utf-8,${encodeURIComponent(content)}`;
        const baseName = `Payflow_${this.resultSource || 'Report'}_${this.result.reportId}`;
        link.download = `${baseName.replace(/[^A-Za-z0-9_-]+/g, '_')}.${extension}`;
        link.style.display = 'none';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    }

    validateInputs() {
        const inputs = [...this.template.querySelectorAll('lightning-input, lightning-combobox')];
        const allValid = inputs.reduce((valid, input) => input.reportValidity() && valid, true);
        if (!allValid) {
            return false;
        }
        if (this.endDate < this.startDate) {
            this.errorMessage = 'End Date must be on or after Start Date.';
            return false;
        }
        return true;
    }
}