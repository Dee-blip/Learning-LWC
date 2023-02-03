// Formula Evaluator
// Class   - DESCRIPTION
// CompConfig - default export of this module
//                  - reset : resets requested values to default values
//                  one comp info, extracts the formula dependent variables
//                  registers the dependency components
//                  when value is changed, setValue method will be called, it'll not only sets the value, but also 
//                  list of components that need to be calculated , list<packCompName> for which formula needs to be calculated

const FORMULA_REGEX = /\${(.*?)}/g;

export default class CompConfig {
    // sfid, product, configName, customFormula, defaultCustValue,value
    // standardValue, min, minError, max, maxError, allowBelowMin, allowAboveMax

    _bindVariables;
    formattedCustomFormula;

    constructor(compInfo) {
        Object.assign(this, compInfo);
        if (this.customFormula) {
            this.formattedCustomFormula = this.customFormula.replace(/[${}]/g, '');
        }
        this.configLabel = this.configLabel || this.configName;

    }

    // Reset to Default Values
    reset() {
        this.requested = this.defaultCustValue;
    }

    // getter
    getCompCustInfo() {
        return {
            sfid: this.sfid, product: this.product, configName: this.configName, configLabel: this.configLabel || this.configName, customFormula: this.customFormula,
            defaultCustValue: this.defaultCustValue, requested: this.requested, standard: this.standard, min: this.min, max: this.max, sequence: this.sequence,
            minError: this.minError, maxError: this.maxError, allowBelowMin: this.allowBelowMin, allowAboveMax: this.allowAboveMax
        };
    }
    // value evaluated from formula
    get evalValue() {
        if (!this.customFormula) {
            return this.requested;//.toFixed(2);
        }
        let evalString = this.customFormula;
        this.bindVariables.forEach((variable) => {
            let [compName, fieldName] = variable.split('.');
            if(fieldName.toLowerCase() === 'requested') { fieldName = 'evalValue'}
            if(fieldName.toLowerCase() === 'standard') { fieldName = 'standard'}
            evalString = evalString.replace(variable, this.dependencyCompConfigs[compName][fieldName]);
        });

        return eval(evalString.replace(/[${}]/g, ''));
    }

    get isBelowMin() {
        return !this.customFormula && this.evalValue < this.min;
    }

    //Set Requested Value
    setValue(value) {
        if (typeof value === 'string') {
            this.requested = value.replace(/^0+/, '');
        } else {
            this.requested = value;
        }
        //Object.values(this.dependencyCompConfigs).forEach((cnf) => {cnf.});
    }

    // get Variables/ Component Names referenced in the formula
    get bindVariables() {

        if (this._bindVariables) {
            return this._bindVariables;
        }

        this._bindVariables = [];

        if (!this.customFormula) {
            return this._bindVariables;
        }

        let matches = this.customFormula.match(FORMULA_REGEX);

        // removes prefix('${') and postfix('}')
        if (matches) {
            matches.forEach((el) => {
                this._bindVariables.push(el.replace(/^\${/, '').replace(/}$/, ''));
            });
        }
        console.log('binded Vars', this._bindVariables);
        return this._bindVariables;
    }
    dependencyCompConfigs = {};

    // Register Objects of Variables/ Component Names referenced in the formula (bindVariables)
    registerDependency(dependencyConfig) {
        this.dependencyCompConfigs[dependencyConfig.configName] = dependencyConfig;
    }
}