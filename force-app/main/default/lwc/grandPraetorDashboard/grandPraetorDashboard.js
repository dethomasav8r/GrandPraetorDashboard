import { LightningElement, track } from 'lwc';
import getDashboardData from '@salesforce/apex/GrandPraetorDashboardController.getDashboardData';
import getContactDetail from '@salesforce/apex/GrandPraetorDashboardController.getContactDetail';
import getOrderLines from '@salesforce/apex/GrandPraetorDashboardController.getOrderLines';

export default class GrandPraetorDashboard extends LightningElement {
    @track dashboardData = [];
    @track isLoading = true;
    @track hasError = false;
    @track errorMessage = '';
    @track debugMessage = '';
    @track showModal = false;
    @track modalContact = null;
    @track modalLoading = false;
    @track showBalanceAlert = false;
    @track alertChapters = [];
    @track showLinesModal = false;
    @track linesModalTitle = '';
    @track linesModalLoading = false;
    @track linesModalEmpty = false;
    @track linesModalLines = [];

    connectedCallback() {
        this.loadDashboardData();
    }

    loadDashboardData() {
        this.isLoading = true;
        this.hasError = false;
        this.debugMessage = 'Calling Apex...';

        getDashboardData()
            .then(result => {
                this.debugMessage = 'Apex returned ' + (result ? result.length : 'null') + ' records'
                    + (result && result[0] && result[0].debugInfo ? ' | ch1=' + result[0].chapterName + ':' + result[0].debugInfo : '');

                if (result && result.length > 0 && result[0].chapterId !== 'DEBUG') {
                    this.dashboardData = this.processData(result);
                    const redChapters = this.dashboardData.filter(c => c.hasBalance && c.maxPostedAge >= 60);
                    if (redChapters.length > 0) {
                        this.alertChapters = redChapters;
                        this.showBalanceAlert = true;
                    }
                } else {
                    this.dashboardData = [];
                }
                this.isLoading = false;
            })
            .catch(error => {
                this.hasError = true;
                let msg = 'Unknown error';
                if (error) {
                    if (error.body && error.body.message) msg = error.body.message;
                    else if (error.message) msg = error.message;
                    else msg = JSON.stringify(error);
                }
                this.errorMessage = msg;
                this.debugMessage = 'ERROR: ' + msg;
                this.isLoading = false;
            });
    }

    // ── Bucket click handler — opens modal ──
    handleBucketClick(event) {
        const chapterId   = event.currentTarget.dataset.chapter;
        const bucket      = event.currentTarget.dataset.bucket;
        const chapterName = event.currentTarget.dataset.chapter
            ? (this.dashboardData.find(c => c.chapterId === chapterId) || {}).chapterName || ''
            : '';
        const bucketLabel = bucket === '0-30'  ? '0–30 Days'  :
                            bucket === '31-60'  ? '31–60 Days' :
                            bucket === '61-90'  ? '61–90 Days' : '90+ Days';

        const chapter = this.dashboardData.find(c => c.chapterId === chapterId);
        this.linesModalTitle   = (chapter ? chapter.chapterName + ' — ' : '') + bucketLabel;
        this.linesModalLoading = true;
        this.linesModalEmpty   = false;
        this.linesModalLines   = [];
        this.showLinesModal    = true;

        getOrderLines({ chapterId, bucket })
            .then(result => {
                const enriched = (result || []).map(ln => this.enrichLine(ln));
                this.linesModalLines   = enriched;
                this.linesModalEmpty   = enriched.length === 0;
                this.linesModalLoading = false;
            })
            .catch(() => {
                this.linesModalEmpty   = true;
                this.linesModalLoading = false;
            });
    }

    closeLinesModal() {
        this.showLinesModal  = false;
        this.linesModalLines = [];
    }

    handleAlertChapterClick(event) {
        const chapterId = event.currentTarget.dataset.chapter;
        const chapter   = this.dashboardData.find(c => c.chapterId === chapterId);

        // Determine the correct bucket based on maxPostedAge
        const age = chapter ? chapter.maxPostedAge : 0;
        let bucket, bucketLabel;
        if (age > 90)      { bucket = '90+';   bucketLabel = '90+ Days'; }
        else if (age > 60) { bucket = '61-90'; bucketLabel = '61–90 Days'; }
        else if (age > 30) { bucket = '31-60'; bucketLabel = '31–60 Days'; }
        else               { bucket = '0-30';  bucketLabel = '0–30 Days'; }

        // Close the alert modal and open the lines modal
        this.showBalanceAlert   = false;
        this.linesModalTitle    = (chapter ? chapter.chapterName + ' — ' : '') + bucketLabel;
        this.linesModalLoading  = true;
        this.linesModalEmpty    = false;
        this.linesModalLines    = [];
        this.showLinesModal     = true;

        getOrderLines({ chapterId, bucket })
            .then(result => {
                const enriched = (result || []).map(ln => this.enrichLine(ln));
                this.linesModalLines   = enriched;
                this.linesModalEmpty   = enriched.length === 0;
                this.linesModalLoading = false;
            })
            .catch(() => {
                this.linesModalEmpty   = true;
                this.linesModalLoading = false;
            });
    }

    enrichLine(ln) {
        return {
            ...ln,
            balanceDueFormatted: this.formatCurrency(ln.balanceDue),
            totalFormatted:      this.formatCurrency(ln.total),
            postedDateFormatted: this.fmtDate(ln.postedDate),
            dueDateFormatted:    this.fmtDate(ln.dueDate),
            lineKey: ln.salesOrderId + (ln.itemName || '')
        };
    }

    fmtDate(val) {
        if (!val) return '—';
        const [y, m, d] = val.split('-');
        return `${parseInt(m)}/${parseInt(d)}/${y}`;
    }

    // ── Contact modal ──
    handleContactClick(event) {
        const contactId = event.currentTarget.dataset.contactid;
        if (!contactId) return;
        this.showModal = true;
        this.modalLoading = true;
        this.modalContact = null;

        getContactDetail({ contactId })
            .then(result => {
                this.modalContact = result ? this.processContactDetail(result) : null;
                this.modalLoading = false;
            })
            .catch(() => { this.modalLoading = false; });
    }

    processContactDetail(c) {
        let address = '';
        if (c.mailingStreet) address += c.mailingStreet;
        if (c.mailingCity)   address += (address ? ', ' : '') + c.mailingCity;
        if (c.mailingState)  address += (address ? ', ' : '') + c.mailingState;
        if (c.mailingPostalCode) address += ' ' + c.mailingPostalCode;
        const displayPhone = c.preferredPhone || c.phone || c.mobilePhone || null;
        const displayEmail = c.preferredEmail || c.email || null;
        const showMobile = c.mobilePhone && c.mobilePhone !== displayPhone;
        return { ...c, displayPhone, displayEmail, showMobile,
                 address: address || null,
                 hasPhone: !!displayPhone, hasEmail: !!displayEmail, hasAddress: !!address };
    }

    closeModal() { this.showModal = false; this.modalContact = null; }
    closeBalanceAlert() { this.showBalanceAlert = false; }

    get modalTitle() { return this.modalContact ? this.modalContact.name : 'Contact Details'; }
    get modalPhoneLink()  { return this.modalContact && this.modalContact.displayPhone  ? `tel:${this.modalContact.displayPhone}`  : '#'; }
    get modalMobileLink() { return this.modalContact && this.modalContact.mobilePhone   ? `tel:${this.modalContact.mobilePhone}`   : '#'; }
    get modalEmailLink()  { return this.modalContact && this.modalContact.displayEmail  ? `mailto:${this.modalContact.displayEmail}` : '#'; }

    isValidEmail(email) {
        return email && email.trim() !== '' && !email.includes('.invalid') && email.includes('@');
    }

    formatCurrency(amount) {
        if (!amount) return '$0';
        return new Intl.NumberFormat('en-US', {
            style: 'currency', currency: 'USD',
            minimumFractionDigits: 0, maximumFractionDigits: 0
        }).format(amount);
    }

    formatDate(dateString) {
        if (!dateString) return '';
        const date = new Date(dateString);
        return date.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
    }

    processData(rawData) {
        if (!rawData || rawData.length === 0) return [];
        return rawData.map(chapter => {
            const processedOfficers = (chapter.chapterOfficers || []).map(o => ({
                ...o, emailLink: this.isValidEmail(o.email) ? `mailto:${o.email}` : null
            }));
            const officerEmails = processedOfficers.filter(o => this.isValidEmail(o.email)).map(o => o.email);

            const processedUndergrads = (chapter.activeUndergrads || []).map(m => ({
                ...m,
                emailLink: this.isValidEmail(m.email) ? `mailto:${m.email}` : null,
                formattedPledgeDate: m.pledgeDate ? this.formatDate(m.pledgeDate) : null,
                formattedInitDate: m.initiationDate ? this.formatDate(m.initiationDate) : null
            }));
            const undergradEmails = processedUndergrads.filter(m => this.isValidEmail(m.email)).map(m => m.email);

            const processedPledges = (chapter.activePledges || []).map(m => ({
                ...m,
                emailLink: this.isValidEmail(m.email) ? `mailto:${m.email}` : null,
                formattedPledgeDate: m.pledgeDate ? this.formatDate(m.pledgeDate) : null,
                formattedInitDate: m.initiationDate ? this.formatDate(m.initiationDate) : null
            }));
            const pledgeEmails = processedPledges.filter(m => this.isValidEmail(m.email)).map(m => m.email);

            const processedMembers = (chapter.activeMembers || []).map(m => ({
                ...m,
                emailLink: this.isValidEmail(m.email) ? `mailto:${m.email}` : null,
                formattedPledgeDate: m.pledgeDate ? this.formatDate(m.pledgeDate) : null,
                formattedInitDate: m.initiationDate ? this.formatDate(m.initiationDate) : null
            }));
            const memberEmails = processedMembers.filter(m => this.isValidEmail(m.email)).map(m => m.email);

            const formattedFoundingDate = chapter.foundingDate ? this.formatDate(chapter.foundingDate) : null;

            return {
                ...chapter,
                chapterOfficers: processedOfficers,
                activeUndergrads: processedUndergrads,
                activePledges: processedPledges,
                activeMembers: processedMembers,
                hasOfficers: processedOfficers.length > 0,
                hasOfficerEmails: officerEmails.length > 0,
                officerMailtoLink: officerEmails.length > 0 ? `mailto:${officerEmails.join(',')}` : null,
                hasUndergrads: processedUndergrads.length > 0,
                hasUndergradEmails: undergradEmails.length > 0,
                undergradMailtoLink: undergradEmails.length > 0 ? `mailto:${undergradEmails.join(',')}` : null,
                hasPledges: processedPledges.length > 0,
                hasPledgeEmails: pledgeEmails.length > 0,
                pledgeMailtoLink: pledgeEmails.length > 0 ? `mailto:${pledgeEmails.join(',')}` : null,
                hasMembers: processedMembers.length > 0,
                hasMemberEmails: memberEmails.length > 0,
                memberMailtoLink: memberEmails.length > 0 ? `mailto:${memberEmails.join(',')}` : null,
                formattedFoundingDate,
                formattedBalance: this.formatCurrency(chapter.totalBalanceDue),
                formatted0to30:   this.formatCurrency(chapter.due0to30),
                formatted31to60:  this.formatCurrency(chapter.due31to60),
                formatted61to90:  this.formatCurrency(chapter.due61to90),
                formatted90Plus:  this.formatCurrency(chapter.due90Plus),
                hasBalance: chapter.totalBalanceDue > 0,
                isRed: chapter.balanceStatus === 'RED' || chapter.balanceStatus === 'AMBER',
                bannerClass: 'chapter-card-header banner-' + (chapter.balanceStatus || 'GREEN').toLowerCase(),
                // Detail panel state
                showDetail: false,
                linesLoading: false,
                linesEmpty: false,
                hasLines: false,
                orderLines: [],
                activeBucket: null,
                activeBucketLabel: ''
            };
        });
    }

    get linesModalHasLines() { return this.linesModalLines.length > 0; }

    get hasChapters() { return !this.isLoading && !this.hasError && this.dashboardData.length > 0; }
    get hasNoChapters() { return !this.isLoading && !this.hasError && this.dashboardData.length === 0; }
}
