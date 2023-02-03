import { api, track, LightningElement } from 'lwc';

export default class LwcIllustrations extends LightningElement {

    @api illustrationsHeading;

    @api illustrationsText;
    @track smallIllustration = false;
    @api get  showIllustration() {
        return this.showIllustration;
    }
    set showIllustration(value) {
        console.log("dummyy");
        this.showIllustration = value;
    }

}