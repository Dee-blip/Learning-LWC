import { LightningElement, track, wire, api } from 'lwc';
import CompConfig from './CompConfig.js';
import getProductRules from '@salesforce/apex/SC_DD_DealDeskCont.getProductRules';
import {serverCallError} from 'c/scUtil';
const COMPUTED_HOURS = 'Computed Total Package Hours/Month';
const ERR_PACK_COMP = {
    title: 'Error Fetching Customization data',
    variant: 'error',
};

export default class DdPackageCustomization extends LightningElement {

    @api prodSelected;
    @api subProdSelected;

    @track compConfigMap = {};
    @track compConfigList;

    @wire(getProductRules, { prod: '$prodSelected', prodType: '$subProdSelected', configValueStr:  '$compData'})
    processComponentRules({ error, data }) {
        if (data) {
            this.setCompInfoData(data);
        } else if (error) {
            serverCallError(this, error, ERR_PACK_COMP);
        }
    }

    _comp;
    @api 
    get compData() {
        return this._comp || '';
    }
    set compData(value) {
        this._comp = value;
        if(value) {
            this.setCompInfoData(JSON.parse(value));
        }
    }

    @api readmode;


    setCompInfoData(data) {

        this.compConfigMap = {};

        if(Object.keys(data).length === 0) {
            return;
        } 

        for (let [compName, compData] of Object.entries(data)) {
            this.compConfigMap[compName] = new CompConfig(compData);
        }

        Object.values(this.compConfigMap).forEach((cmp) => {
            cmp.bindVariables.forEach((bindVar) => {
                let [compName] = bindVar.split('.');
                cmp.registerDependency(this.compConfigMap[compName]);
            });
        });

        this.compConfigList = Object.values(this.compConfigMap);
        this.compConfigList.sort((a, b) => a.sequence - b.sequence);

        let configData = {};

        for(let [name, cmpConfig] of Object.entries(this.compConfigMap)) {
            configData[name] = cmpConfig.getCompCustInfo();
        }
        let belowMinComp =  Object.values(this.compConfigMap).find(el => el.isBelowMin);

        this.dispatchEvent(new CustomEvent('customization', {
            detail: {
                requestedHours: this.compConfigMap[COMPUTED_HOURS].evalValue.toFixed(1),
                packageCompInfo: JSON.stringify(configData),
                isBelowMin: belowMinComp && belowMinComp.isBelowMin,
                initialization:true
            }
        }));
    }

    @track disableDone = false;

    @track invalidFields=[];

    handleOnChange(ev) {
        let configName = ev.target.getAttribute('data-name');
        if(!ev.target.value || !ev.target.checkValidity()) {
            this.invalidFields.push(configName);
        } else {
            this.invalidFields = this.invalidFields.filter(item => item !== configName)
            // this.invalidFields.push(configName);
        }

        this.disableDone = this.invalidFields.length > 0;
        let value = ev.target.value > 0 ? ev.target.value: 0;
        this.compConfigMap[configName].setValue(value);
        this.compConfigList = [...this.compConfigList];
    }

    handleReset(ev) {
        this.compConfigList.forEach(el => el.reset());
        this.invalidFields = [];
        this.disableDone = false;
        this.compConfigList = [...this.compConfigList];
    }
    handleDone(ev) {

        let configData = {};

        for(let [name, cmpConfig] of Object.entries(this.compConfigMap)) {
            configData[name] = cmpConfig.getCompCustInfo();
        }
        let belowMinComp =  Object.values(this.compConfigMap).find(el => el.isBelowMin);
        this.dispatchEvent(new CustomEvent('customization', {
            detail: {
                requestedHours: this.compConfigMap[COMPUTED_HOURS].evalValue.toFixed(1),
                packageCompInfo: JSON.stringify(configData),
                isBelowMin: belowMinComp && belowMinComp.isBelowMin
            }
        }));

    }

    renderedCallback() {
        this.validateInput();
    }

    validateInput() {
        this.template.querySelectorAll('lightning-input').forEach((el) => {
            el.showHelpMessageIfInvalid();
        });
    }
}