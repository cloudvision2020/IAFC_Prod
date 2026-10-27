import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOrderSummary from '@salesforce/apex/OrderSummaryBuilderController.getOrderSummary';

export default class OrderSummaryBuilder extends LightningElement {
   
    _recordId;
    _hasLoaded = false;

    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        if (value && !this._hasLoaded) {
            this._hasLoaded = true;
            this.loadData();
        }
    }

    @track rows = [];
    @track filteredRows = [];
    @track businessGroupOptions = [];

    pastDueTotal = 0;
    upcomingTotal = 0;
    openTotal = 0;

    activeTab = 'open';          // 'open' | 'all'
    searchKey = '';
    selectedBusinessGroup = '';  // '' = all
    startDate = `${new Date().getFullYear()}-01-01`;
    endDate = `${new Date().getFullYear()}-12-31`;



    selectedIds = new Set();
    isLoading = false;
    error;

    connectedCallback() {
        // Fallback for cases where recordId is already set before
        // this component gets inserted into the DOM.
        if (this.recordId && !this._hasLoaded) {
            this._hasLoaded = true;
            this.loadData();
        }
    }

    get isOpenTab() {
        return this.activeTab === 'open';
    }

    async loadData() {
        this.isLoading = true;
        this.error = undefined;
        try {
            const result = await getOrderSummary({
                accountId: this.recordId,
                businessGroupId: this.selectedBusinessGroup || null,
                openOnly: this.activeTab === 'open'
            });

            this.pastDueTotal = result.pastDueTotal || 0;
            this.upcomingTotal = result.upcomingTotal || 0;
            this.openTotal = result.openTotal || 0;

            this.rows = (result.rows || []).map(r => ({
                ...r,
                selected: this.selectedIds.has(r.id)
            }));

            this.businessGroupOptions = [
                { label: 'All Business Groups', value: '' },
                ...(result.businessGroups || []).map(bg => ({
                    label: bg.label, value: bg.value
                }))
            ];

            this.applyClientFilters();
        } catch (e) {
            this.error = this.reduceError(e);
        } finally {
            this.isLoading = false;
        }
    }

    // ---- Client-side search + date filtering ----
    applyClientFilters() {
        let data = [...this.rows];

        if (this.searchKey) {
            const key = this.searchKey.toLowerCase();
            data = data.filter(r =>
                (r.orderNumber && r.orderNumber.toLowerCase().includes(key)) ||
                (r.fullName && r.fullName.toLowerCase().includes(key)) ||
                (r.membershipType && r.membershipType.toLowerCase().includes(key)) ||
                (r.division && r.division.toLowerCase().includes(key)) ||
                (r.sections && r.sections.toLowerCase().includes(key))
            );
        }
        if (this.startDate) {
            data = data.filter(r => r.dueDate && r.dueDate >= this.startDate);
        }
        if (this.endDate) {
            data = data.filter(r => r.dueDate && r.dueDate <= this.endDate);
        }
        this.filteredRows = data;
    }

    get orderCount() {
        return this.filteredRows.length;
    }

    get hasRows() {
        return this.filteredRows.length > 0;
    }

    get selectAllChecked() {
        return this.hasRows &&
            this.filteredRows.every(r => this.selectedIds.has(r.id));
    }

    get actionsDisabled() {
        return this.selectedIds.size === 0;
    }

    get openTabClass() {
        return 'slds-tabs_default__item' + (this.activeTab === 'open' ? ' slds-is-active' : '');
    }
    get allTabClass() {
        return 'slds-tabs_default__item' + (this.activeTab === 'all' ? ' slds-is-active' : '');
    }

    // ---- Event handlers ----
    handleTabOpen() {
        if (this.activeTab !== 'open') { this.activeTab = 'open'; this.loadData(); }
    }
    handleTabAll() {
        if (this.activeTab !== 'all') { this.activeTab = 'all'; this.loadData(); }
    }
    handleSearch(e) {
        this.searchKey = e.target.value;
        this.applyClientFilters();
    }
    handleBusinessGroup(e) {
        this.selectedBusinessGroup = e.detail.value;
        this.loadData();
    }
    handleStartDate(e) { this.startDate = e.target.value; this.applyClientFilters(); }
    handleEndDate(e)   { this.endDate = e.target.value; this.applyClientFilters(); }

    handleSelectAll(e) {
        const checked = e.target.checked;
        this.filteredRows.forEach(r => {
            if (checked) this.selectedIds.add(r.id);
            else this.selectedIds.delete(r.id);
        });
        this.syncSelection();
    }
    handleRowSelect(e) {
        const id = e.target.dataset.id;
        if (e.target.checked) this.selectedIds.add(id);
        else this.selectedIds.delete(id);
        this.syncSelection();
    }
    syncSelection() {
        this.selectedIds = new Set(this.selectedIds); // trigger reactivity
        this.rows = this.rows.map(r => ({ ...r, selected: this.selectedIds.has(r.id) }));
        this.applyClientFilters();
        this.filteredRows = this.filteredRows.map(r => ({
            ...r, selected: this.selectedIds.has(r.id)
        }));
    }

    // ---- PDF preview / download ----
    handlePreview() {
        const url = this.buildPdfUrl(false);
        if (url) window.open(url, '_blank');
    }
    handleDownload() {
        const url = this.buildPdfUrl(true);
        if (url) window.open(url, '_blank');
    }
    buildPdfUrl(forceDownload) {
        const selected = this.rows.filter(r => this.selectedIds.has(r.id));
        if (!selected.length) {
            this.toast('No orders selected', 'Select at least one order.', 'warning');
            return null;
        }
        const encIds = selected.map(r => r.encryptedId).filter(Boolean);
        if (!encIds.length) {
            this.toast('Missing data', 'Selected orders have no encrypted id.', 'error');
            return null;
        }
        const idParam = encodeURIComponent(encIds.join(','));
        return `/apex/MultiOrderInvoicePDF?ids=${idParam}&dl=${forceDownload ? '1' : '0'}`;
    }

    handlePay() {
        const url = this.buildPaymentUrl();
        if (url) window.open(url, '_blank');
    }
    
    buildPaymentUrl() {
    const selected = this.rows.filter(r => this.selectedIds.has(r.id));
    if (!selected.length) {
        this.toast('No orders selected', 'Select at least one order.', 'warning');
        return null;
    }
    const orderIds = selected.map(r => r.id).join(',');
    const retUrl = `//${window.location.host}/apex/LTE__OrderSummaryBuilder?id=${this.recordId}`;
    const url = `/apex/LTE__ApplyPayment?orderIds=${encodeURIComponent(orderIds)}&retUrl=${encodeURIComponent(retUrl)}`;
    console.log('Payment URL:', url); 
    return url;
}

    handleClose() {
        // navigate back — adjust to your container
        window.history.back();
    }

    // ---- helpers ----
    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
    reduceError(e) {
        if (Array.isArray(e?.body)) return e.body.map(x => x.message).join(', ');
        return e?.body?.message || e?.message || 'Unable to load orders.';
    }
}