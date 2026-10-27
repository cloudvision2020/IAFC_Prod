import { LightningElement, wire, track } from 'lwc';
import getHeaderMenus from '@salesforce/apex/HeaderMenuController.getHeaderMenus';

export default class Dashboard extends LightningElement {
    homeUrl = '/s';
    logoUrl =
        'https://iafchelix.my.salesforce.com/servlet/servlet.ImageServer?id=015V100000H9fGi&oid=00D1N000002qxI8&lastMod=1772459848000';

    @track menus = [];
    errorMessage;
    isLoaded = false;

    openKey = null; // which parent dropdown is open

    connectedCallback() {
        this._outsideClick = this.handleOutsideClick.bind(this);
        this._escClose = this.handleEscClose.bind(this);
        document.addEventListener('click', this._outsideClick);
        document.addEventListener('keydown', this._escClose);
    }

    disconnectedCallback() {
        document.removeEventListener('click', this._outsideClick);
        document.removeEventListener('keydown', this._escClose);
    }

    get hasMenus() {
        return Array.isArray(this.menus) && this.menus.length > 0;
    }

    @wire(getHeaderMenus)
    wiredMenus({ data, error }) {
        this.isLoaded = true;

        if (data) {
            this.errorMessage = null;

            this.menus = (data || []).map((m) => {
                const items = Array.isArray(m.items) ? m.items : [];
                const hasItems = items.length > 0;

                const normalizedItems = items.map((it) => ({
                    label: it.label,
                    url: it.url,
                    target: this.getTarget(it.url)
                }));

                return {
                    developerName: m.developerName,
                    label: m.label,
                    url: m.url,
                    target: this.getTarget(m.url),
                    hasItems,
                    items: normalizedItems,
                    isOpen: false,
                    wrapperClass: hasItems ? 'menu-item has-dropdown' : 'menu-item'
                };
            });

            // eslint-disable-next-line no-console
            console.log('MENUS DATA =>', JSON.stringify(this.menus));
        } else if (error) {
            this.menus = [];
            this.errorMessage = this.reduceError(error);
            // eslint-disable-next-line no-console
            console.error('MENUS ERROR =>', JSON.stringify(error));
        }
    }

    handleToggle(event) {
        event.preventDefault();
        event.stopPropagation();

        const key = event.currentTarget.dataset.key;

        // toggle logic: same key -> close, different -> open that one
        this.openKey = this.openKey === key ? null : key;

        this.menus = this.menus.map((m) => {
            const isOpen = m.developerName === this.openKey;
            return {
                ...m,
                isOpen,
                wrapperClass: m.hasItems
                    ? `menu-item has-dropdown ${isOpen ? 'open' : ''}`
                    : 'menu-item'
            };
        });
    }

    handleItemClick(event) {
        // allow navigation, but close dropdown immediately for UX
        event.stopPropagation();
        this.closeAll();
    }

    handleOutsideClick(event) {
        // if click happened outside the nav bar, close
        const clickedInside = this.template.contains(event.target);
        if (!clickedInside) return;

        // if click is not within an open menu-item, close
        const withinMenuItem = event.target.closest('.menu-item');
        const withinDropdown = event.target.closest('.menu-dropdown');
        const withinToggle = event.target.closest('.nav-link');

        if (!withinMenuItem && !withinDropdown && !withinToggle) {
            this.closeAll();
        }
    }

    handleEscClose(event) {
        if (event.key === 'Escape') this.closeAll();
    }

    closeAll() {
        this.openKey = null;
        this.menus = this.menus.map((m) => ({
            ...m,
            isOpen: false,
            wrapperClass: m.hasItems ? 'menu-item has-dropdown' : 'menu-item'
        }));
    }

    getTarget(url) {
        if (!url) return '_self';
        const u = String(url).trim();
        if (u.startsWith('http://') || u.startsWith('https://')) return '_blank';
        return '_self';
    }

    reduceError(err) {
        try {
            if (Array.isArray(err?.body)) {
                return err.body.map((e) => e.message).join(', ');
            }
            return err?.body?.message || err?.message || JSON.stringify(err);
        } catch (e) {
            return 'Unknown error';
        }
    }
}