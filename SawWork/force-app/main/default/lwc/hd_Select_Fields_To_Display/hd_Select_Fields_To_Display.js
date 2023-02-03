import { LightningElement, api } from 'lwc';

export default class Hd_Select_Fields_To_Display extends LightningElement {
    @api defaultOptions;
    @api requiredOptions;
    @api listOptions;
    @api showContent;
    @api updatedOptions = {};
    handleChange(event) {
        /* eslint-disable-next-line */
        this.defaultOptions = event.detail.value;
        this.listOptions.forEach(option => {
            if (this.defaultOptions.includes(option.value)) {
                this.updatedOptions[option.value] = option.label;
            }
        });
    }

    get defaultValues() {
        return this.defaultOptions ?? [];
    }

    get requiredValues() {
        return this.requiredOptions ?? [];
    }

    get allValues() {
        return this.listOptions ?? [];
    }
}