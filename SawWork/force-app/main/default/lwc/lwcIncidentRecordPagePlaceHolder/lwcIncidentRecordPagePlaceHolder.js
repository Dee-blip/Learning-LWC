import { LightningElement, api } from 'lwc';

export default class LwcIncidentRecordPagePlaceHolder extends LightningElement {
    @api type;

    get showHighlightHolder(){
        return (this.type === 'highlightPanel') ? true : false;
    }

    get showClientHolder(){
        return (this.type === 'clientDetail') ? true : false;
    }
}