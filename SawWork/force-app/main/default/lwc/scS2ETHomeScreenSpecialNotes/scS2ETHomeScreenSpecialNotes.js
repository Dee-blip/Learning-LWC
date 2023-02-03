import {LightningElement,api} from 'lwc';
import updateSpecialNotes from "@salesforce/apex/SC_SecurityServices_Ctrlr.updateSpecialNotes";
import getSpecialNotes from "@salesforce/apex/SC_SecurityServices_Ctrlr.getSpecialNotes";
import {ShowToastEvent} from "lightning/platformShowToastEvent";

const POLLER_INTERVAL = 600000;//10 minutes

export default class ScS2EtHomeScreenSpecialNotes extends LightningElement {

    _specialNotes;
    _lastModifiedBy;
    _lastModifiedDate;

    mode = 'view';
    showSpinner=false;
    pollerId;

    async connectedCallback() {
        this.fetchSpecialNotes();
        this.startPoller();
        window.addEventListener("visibilitychange",()=>{
            if (document.visibilityState !== 'visible') this.stopPoller();
            else this.pollerId = this.startPoller();
        });
    }

    disconnectedCallback() {
        this.stopPoller();
    }

    @api
    set specialNotes(value) {
        this._specialNotes = value;
        this.updateRichTextViewContainer(value);
    }
    get specialNotes() {
        return this._specialNotes;
    }
    @api
    set lastModifiedBy(val){
        this._lastModifiedBy = val;
    }
    get lastModifiedBy(){
        return this._lastModifiedBy;
    }

    @api
    set lastModifiedDate(val){
        this._lastModifiedDate = val;
    }
    get lastModifiedDate(){
        return this._lastModifiedDate;
    }

    get isEditMode(){
        return this.mode === 'edit';
    }

    get isViewMode(){
        return this.mode === 'view';
    }

    onEditClick(){
        this.mode = 'edit';
        this.fetchSpecialNotes();
    }

    onCancelClick(){
        this.mode = 'view';
    }

    async onSaveClick(){
        try{
            this.showSpinner = true;
            await updateSpecialNotes({
                notes: this.specialNotes
            });
            this.showToast('Success!','Special Notes updated.');
            this.mode = 'view';
            this.updateRichTextViewContainer(this.specialNotes);
        }catch (e) {
            console.error(e);
            //TODO [Added by jrathod on 9/27/21] Parse error message
            this.showToast('Could not update Special Notes.',e.message,'error');
        }finally {
            this.showSpinner = false;
        }
    }

    onSpecialNotesChange(e){
        this._specialNotes = e.detail.value;
    }

    showToast(title,message,variant='success'){
        this.dispatchEvent(new ShowToastEvent({
            variant,
            title,
            message,
        }))
    }

    async fetchSpecialNotes(){
        try{
            this.showSpinner = true;
            let response = (await getSpecialNotes())|| {};
            console.log(response);
            this._specialNotes = response.notes;
            this._lastModifiedDate = response.lastModifiedDate;
            this._lastModifiedBy = response.lastModifiedBy;
            this.updateRichTextViewContainer(response.notes);
        }catch (e) {
            console.error(e);
        }finally {
            this.showSpinner = false;
        }
    }

    updateRichTextViewContainer(content){
        let elem = this.template.querySelector('.rich-text-container');
        //Reason to disable eslint on this line: Need to display rich text on the page. Standard lightning-formatted-rich-text component could not be used as it did not allow min-height to be set.
        //eslint-disable-next-line @lwc/lwc/no-inner-html
        if (elem) elem.innerHTML = content || '';
    }

    startPoller(){
        this.fetchSpecialNotes();
        return window.setInterval(()=>{
            this.fetchSpecialNotes();
        },POLLER_INTERVAL);
    }

    stopPoller(){
        window.clearInterval(this.pollerId);
    }


}