import { LightningElement, api } from 'lwc';

export default class Hd_CMR_Cell_Template extends LightningElement {
    @api cellValue;

    get showPopover() {
        return this.cellValue.length > 100;
    }
}