import { LightningElement, track, api } from 'lwc';

export default class ComboBox extends LightningElement {
    
    @api variant; // 'label-hidden', 'label-inline'
    @api placeholder;
    @api options;
    @api required;


    @api
    get value() {
        return this.selItem;
    }
    set value(value) {
        if(value) {
            if(this.processedListData) {
                this.selItem = this.processedListData.find(el => el.key === value);        
            }
        }
    }
    @api label;
    @api listData;
    @api textField;
    @api metaTextField;
    @api keyField;
    @api iconPropsField;
    @api props;
    @api noResultsMsg;
    @api disabled;

    get selItemCss() {
       return  'slds-combobox__form-element slds-input-has-icon ' + ( this.selItem.iconName ? 'slds-input-has-icon_left-right' : 'slds-input-has-icon_right' );
    }
    // local varible, converts user input into format consumable by this component
   get processedListData() {
    let props = this.props || {};
    let procData = [];
    let iconProps = props.iconProps || {};
    let iPropFields = props.iconFields ;

    if(Array.isArray(this.options)) 
    {
        this.options.forEach(el => 
        {
            if(!this.searchStr || el[props.textField].toLowerCase().includes(this.searchStr.toLowerCase())) {
                
            procData.push({
                key: el[props.keyField],
                iconName: iPropFields? el[iPropFields.name]: iconProps.name,
                iconText: iPropFields? el[iPropFields.text]: iconProps.text,
                iconSize: iPropFields? el[iPropFields.size]: iconProps.size,
                iconVariant: iPropFields? el[iPropFields.variant]: iconProps.size,
                text: el[props.textField],
                metaText: el[props.metaTextField]
            });
        }
        });
    }
    
    return procData; 
   }


    get showLabel() 
    {
        return this.variant !== 'label-hidden';
    }

    get formElCss() 
    {

        if(this.variant === 'label-inline') {
            return 'slds-form-element slds-form-element_horizontal';
        }
        else if(this.variant === 'label-stacked') {
            return 'slds-form-element slds-form-element_stacked';
        }
        return 'slds-form-element';
    }
    @track comboCss = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';

    handleInpFocus() 
    {
        console.log('IN handleInpFocus');
            this.comboCss = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open';
    }

    @track inpErrorMsg;

    handleOnBlur() 
    {
        this.comboCss = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
        this.reportValidity();
    }



    @api checkValidity() 
    {
        return this.selItem || !this.required;
    }

    @api reportValidity() 
    {

        if(this.checkValidity()) 
        {
            this.inpErrorMsg  = '';
            this.inpCss =  'slds-combobox_container slds-has-selection';
            return true;
        }
        this.inpCss =  'slds-combobox_container slds-has-selection slds-has-error';
        this.inpErrorMsg = 'Complete this field.'
        return false;
    }
    @track inpCss = 'slds-combobox_container slds-has-selection';

    
    get noresults() 
    {
        return this.noResultsMsg && (!this.processedListData || this.processedListData.length === 0);
    }

    @track searchStr;
    handleInpChange(ev) 
    {
        if(ev.keyCode !== 13)
        {
            let inp = this.template.querySelector('input');
            let x = this.dispatchEvent(new CustomEvent('change', {detail: inp.value, cancelable: true}));
    
            if(x) {
                this.searchStr = inp.value;
            }
        }
    }

    @track selItem = '';
    handleSelect(ev) 
    {
        const selKey = ev.detail;

        this.processedListData.forEach((el) => {
            if( el.key === selKey) {
                this.selItem = el;
            }
        });

        let selOpt;

        this.options.forEach((el) => {
            if( el[this.props.keyField] === selKey) {
                selOpt = el;
            }
        });
        
        this.dispatchEvent(new CustomEvent('select', {detail: selOpt}));

    }

    inputFocus;

    handleRemoveAcc(ev) {
        ev.preventDefault();
        if(ev.detail === 1)
        {
            this.selItem  = null;
            this.searchStr = null;
            this.dispatchEvent(new CustomEvent('select', {detail: ''}));
            this.inputFocus = true              
        }
    }
    renderedCallback() {
        if(this.inputFocus && this.template.querySelector('[data-id="input"]')) {
            this.template.querySelector('[data-id="input"]').focus();  
            this.inputFocus = false;
        }
    }
}