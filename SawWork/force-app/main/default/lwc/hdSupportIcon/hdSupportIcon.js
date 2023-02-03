import { LightningElement, api } from 'lwc';

export default class HdSupportIcon extends LightningElement {
    @api supportLevel;

    get isL1() {
        return this.supportLevel === 'L1';
    }

    get isL2() {
        return this.supportLevel === 'L2';
    }

    get isL3() {
        return this.supportLevel === 'L3';
    }
}