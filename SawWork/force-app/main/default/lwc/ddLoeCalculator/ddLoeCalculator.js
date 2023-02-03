import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
    
export default class DdLoeCalculator extends LightningElement {

    @api loehours;
    _loeid;
    @api 
    get loeid() {
        return this._loeid || 'LOE';
    }
    set loeid(value) {
        this._loeid = value;
    }

    handleDone(ev) {
        let reqHours = this.template.querySelector('.loehours').value;
        this.dispatchEvent(new CustomEvent('loe', {
            detail: {
                requestedHours: reqHours.replace(/^0+/, '') || 0,
                loeId: this.template.querySelector('.loeid').value || 'LOE'
            }
        }));
    }
    handleCalcel(ev) {
        this.dispatchEvent(new CustomEvent('cancel'));
    }

}