import { LightningElement, api } from 'lwc';

export default class SearchAkamaiQueryIntentResults extends LightningElement {
    @api queryintentresult;
    @api keyword;
    @api userdetails;
    @api captureaudit;

    redirectToURL(evt){
        this.captureaudit(this.keyword, 'click.productSection', 0, this.queryintentresult[evt.currentTarget.dataset.value].title);
        window.open(this.queryintentresult[evt.currentTarget.dataset.value].url, '_blank');
    }
}