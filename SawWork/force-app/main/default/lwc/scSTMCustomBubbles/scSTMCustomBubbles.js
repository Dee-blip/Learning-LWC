import { LightningElement, api } from 'lwc';

export default class ScSTMCustomBubbles extends LightningElement {
    @api teamsPrimary;
    @api teamsSecondary;
    @api teamsOthers;
    @api accountsPrimary;
    @api accountsSecondary;
}