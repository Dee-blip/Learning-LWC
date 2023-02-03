import { LightningElement, api } from 'lwc';

export default class Hd_Sharing_Settings extends LightningElement {
    @api showContent;
    options = [
        { label: 'Only I can see this list view', value: 'Private' },
        { label: 'All users can see this list view', value: 'Public' },
        { label: 'Share lit view with groups of users', value: 'Shared' }
    ];

    @api defaultVisibility;
}