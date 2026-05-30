import { LightningElement, track } from 'lwc';
import getDashboardData from '@salesforce/apex/GrandPraetorDashboardController.getDashboardData';
import getContactDetail from '@salesforce/apex/GrandPraetorDashboardController.getContactDetail';

export default class GrandPraetorDashboard extends LightningElement {
    @track dashboardData = [];
    @track isLoading = true;
    @track hasError = false;
    @track errorMessage = '';
    @track debugMessage = '';
    @track showModal = false;
    @track modalContact = null;
    @track modalLoading = false;

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
                    + (result && result[0] && result[0].debugInfo ? ' | debug=' + result[0].debugInfo : '');
                if (result && result.length > 0 && result[0].chapterId !== 'DEBUG') {
                    this.dashboardData = this.processData(result);
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
            .catch(() => {
                this.modalLoading = false;
            });
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

        return {
            ...c,
            displayPhone,
            displayEmail,
            showMobile,
            address: address || null,
            hasPhone: !!displayPhone,
            hasEmail: !!displayEmail,
            hasAddress: !!address
        };
    }

    closeModal() {
        this.showModal = false;
        this.modalContact = null;
    }

    get modalTitle() {
        return this.modalContact ? this.modalContact.name : 'Contact Details';
    }

    get modalPhoneLink() {
        return this.modalContact && this.modalContact.displayPhone
            ? `tel:${this.modalContact.displayPhone}` : '#';
    }

    get modalMobileLink() {
        return this.modalContact && this.modalContact.mobilePhone
            ? `tel:${this.modalContact.mobilePhone}` : '#';
    }

    get modalEmailLink() {
        return this.modalContact && this.modalContact.displayEmail
            ? `mailto:${this.modalContact.displayEmail}` : '#';
    }

    isValidEmail(email) {
        return email && email.trim() !== '' && !email.includes('.invalid') && email.includes('@');
    }

    processData(rawData) {
        if (!rawData || rawData.length === 0) return [];
        return rawData.map(chapter => {
            const formattedFoundingDate = chapter.foundingDate
                ? this.formatDate(chapter.foundingDate) : null;
            const processedOfficers = (chapter.chapterOfficers || []).map(o => ({
                ...o, emailLink: this.isValidEmail(o.email) ? `mailto:${o.email}` : null
            }));
            const officerEmails = processedOfficers.filter(o => this.isValidEmail(o.email)).map(o => o.email);
            const officerMailtoLink = officerEmails.length > 0 ? `mailto:${officerEmails.join(',')}` : null;

            const processedUndergrads = (chapter.activeUndergrads || []).map(m => ({
                ...m,
                emailLink: this.isValidEmail(m.email) ? `mailto:${m.email}` : null,
                formattedPledgeDate: m.pledgeDate ? this.formatDate(m.pledgeDate) : null,
                formattedInitDate: m.initiationDate ? this.formatDate(m.initiationDate) : null
            }));
            const undergradEmails = processedUndergrads.filter(m => this.isValidEmail(m.email)).map(m => m.email);
            const undergradMailtoLink = undergradEmails.length > 0 ? `mailto:${undergradEmails.join(',')}` : null;

            const processedPledges = (chapter.activePledges || []).map(m => ({
                ...m,
                emailLink: this.isValidEmail(m.email) ? `mailto:${m.email}` : null,
                formattedPledgeDate: m.pledgeDate ? this.formatDate(m.pledgeDate) : null,
                formattedInitDate: m.initiationDate ? this.formatDate(m.initiationDate) : null
            }));
            const pledgeEmails = processedPledges.filter(m => this.isValidEmail(m.email)).map(m => m.email);
            const pledgeMailtoLink = pledgeEmails.length > 0 ? `mailto:${pledgeEmails.join(',')}` : null;

            const processedMembers = (chapter.activeMembers || []).map(m => ({
                ...m,
                emailLink: this.isValidEmail(m.email) ? `mailto:${m.email}` : null,
                formattedPledgeDate: m.pledgeDate ? this.formatDate(m.pledgeDate) : null,
                formattedInitDate: m.initiationDate ? this.formatDate(m.initiationDate) : null
            }));
            const memberEmails = processedMembers.filter(m => this.isValidEmail(m.email)).map(m => m.email);
            const memberMailtoLink = memberEmails.length > 0 ? `mailto:${memberEmails.join(',')}` : null;

            return {
                ...chapter,
                chapterOfficers: processedOfficers,
                activeUndergrads: processedUndergrads,
                activePledges: processedPledges,
                activeMembers: processedMembers,
                hasOfficers: processedOfficers.length > 0,
                hasOfficerEmails: officerEmails.length > 0, officerMailtoLink,
                hasUndergrads: processedUndergrads.length > 0,
                hasUndergradEmails: undergradEmails.length > 0, undergradMailtoLink,
                hasPledges: processedPledges.length > 0,
                hasPledgeEmails: pledgeEmails.length > 0, pledgeMailtoLink,
                hasMembers: processedMembers.length > 0,
                formattedFoundingDate,
                hasMemberEmails: memberEmails.length > 0, memberMailtoLink
            };
        });
    }

    formatDate(dateString) {
        if (!dateString) return '';
        const date = new Date(dateString);
        return date.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
    }

    get hasChapters() { return !this.isLoading && !this.hasError && this.dashboardData.length > 0; }
    get hasNoChapters() { return !this.isLoading && !this.hasError && this.dashboardData.length === 0; }
}
