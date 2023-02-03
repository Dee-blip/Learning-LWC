import { LightningElement, track, wire, api } from 'lwc';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import getFields from '@salesforce/apex/HD_Advanced_Search_Controller.getFields';
import getAdvancedSearchFilter from '@salesforce/apex/HD_Advanced_Search_Controller.getAdvancedSearchFilter';

export default class HdAdvancedSearch extends LightningElement {
    fieldmetadata;
    @api objectName;
    @api size;
    isCustomLogicSelected;
    @track conditions = [
        { fieldApiName: '', operator: '', operators: this.operators, fieldValue: '', order: 1, type: 'text', isPicklist: false, picklistValues: [], isLookup: false, isLWCInput: true, lookupType: '' }
    ];
    fieldToBeRetrieved;
    recordTypeId;
    isLoading = true;
    conditionOrderWIP;
    transactionStatus;
    isError;
    errorMessage;
    sfTypeToJSTypeMap = new Map([
        ['STRING', 'text'],
        ['ID', 'text'],
        ['BOOLEAN', 'toggle'],
        ['DOUBLE', 'number'],
        ['DATETIME', 'datetime'],
        ['REFERENCE', 'text'],
        ['PICKLIST', 'text'],
        ['URL', 'url'],
        ['TEXTAREA', 'error'],
        ['DATE', 'date']]);
    criteriaOptions = [
        { label: 'All Conditions Are Met (AND)', value: ' AND ' },
        { label: 'Any Condition Is Met (OR)', value: ' OR ' },
        { label: 'Custom Filter Logic', value: ' CUSTOM ' }
    ];

    operators = [
        { label: 'equal to', value: '=', allowedTypes: ['STRING', 'DOUBLE', 'DATETIME', 'DATE', 'REFERENCE', 'PICKLIST', 'URL', 'ID', 'BOOLEAN'] },
        { label: 'not equal to', value: '!=', allowedTypes: ['STRING', 'DOUBLE', 'DATETIME', 'DATE', 'REFERENCE', 'PICKLIST', 'URL', 'ID', 'BOOLEAN'] },
        { label: 'greater than', value: '>', allowedTypes: ['DOUBLE', 'DATETIME', 'DATE'] },
        { label: 'less than', value: '<', allowedTypes: ['DOUBLE', 'DATETIME', 'DATE'] },
        { label: 'greater than or equal to', value: '>=', allowedTypes: ['DOUBLE', 'DATETIME', 'DATE'] },
        { label: 'less than or equal to', value: '<=', allowedTypes: ['DOUBLE', 'DATETIME', 'DATE'] }
    ];

    @wire(getObjectInfo, { objectApiName: '$objectName' })
    getObjectData({ error, data }) {
        if (data) {
            if (this.recordTypeId == null)
                this.recordTypeId = data.defaultRecordTypeId;
        }
        else if (error) {
            this.isError = true;
            this.errorMessage = error.body.message;
        }
    }

    @wire(getFields, { objectName: '$objectName' })
    handleFieldListRetrieval({ error, data }) {
        if (data) {
            let parsedData = JSON.parse(data);
            this.fieldmetadata = [];
            parsedData.forEach(field => {
                if (field.fieldType !== 'TEXTAREA') {
                    this.fieldmetadata.push({ label: field.fieldLabel, value: field.fieldApiName, type: field.fieldType, fieldTypeApiName: field.typeApiName });
                }
            });
            this.isLoading = false;
        }
        else if (error) {
            this.isError = true;
            this.errorMessage = error.body.message;
        }
    }
    handleConditionsCriteriaChange(event) {
        this.isCustomLogicSelected = event.detail.value === ' CUSTOM ';
    }

    handleSearchClick() {
        let allValid = [...this.template.querySelectorAll('lightning-input'), this.template.querySelector('c-hd-lookup')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.reportValidity();
            }, true);
        allValid = allValid && [...this.template.querySelectorAll('lightning-combobox')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);
        if (!allValid) {
            this.isError = true;
            this.errorMessage = 'Please enter values for all the conditions';
        }
        else {
            let logicalOperator = this.template.querySelector("[data-id='logicalOperator']").value;
            let customLogic = '';
            if (logicalOperator === ' CUSTOM ') {
                customLogic = this.template.querySelector("[data-id='customLogic']").value;
            }
            if (!this.validateFilterLogicExpression(logicalOperator, customLogic)) {
                this.isLoading = true;
                getAdvancedSearchFilter({ logicalOperator: logicalOperator, filterLogic: customLogic, filterConditions: JSON.stringify(this.conditions) })
                    .then(result => {
                        this.isLoading = false;
                        this.dispatchEvent(new CustomEvent('searchcriteriadecoded', {
                            detail: result,
                            bubbles: true,
                            isComposed: true
                        }));
                    })
                    .catch(error => {
                        this.isLoading = false;
                        this.isError = true;
                        this.errorMessage = error.body.message;
                    });
            }
        }

    }

    validateFilterLogicExpression(logicalOperator, customLogic) {
        if (logicalOperator === ' CUSTOM ' && !customLogic) {
            this.isError = true;
            this.errorMessage = 'Custom Logic is not specified.'
            return this.isError;
        }

        for (let iterator of customLogic) {
            if (!isNaN(iterator) && parseInt(iterator, 10) > this.conditions.length) {
                this.isError = true;
                this.errorMessage = 'The operand place holder numbers exceed the number of conditions.';
                return this.isError;
            }
        }

        let brackets = [];
        for (let char of customLogic) {
            if (char === '(' || char === '{' || char === '[') {
                brackets.push(char);
            }
            else if (char === ')' || char === '}' || char === ']') {
                if (brackets.length > 0) {
                    brackets.pop();
                }
            }
        }

        if (brackets.length !== 0) {
            this.isError = true;
            this.errorMessage = 'The expression has unbalanced paranthesis';
            return this.isError;
        }
        this.isError = false;
        this.errorMessage = '';
        return this.isError;
    }

    handleFieldNameChange(event) {
        let order = event.target.dataset.id;
        let type;
        let fieldType;
        this.fieldmetadata.forEach(field => {
            if (field.value === event.detail.value) {
                type = field.type;
                fieldType = field.fieldTypeApiName;
            }
        })
        this.conditions.forEach(condition => {
            if (condition.order === parseInt(order, 10)) {
                condition.type = this.sfTypeToJSTypeMap.get(type);
                condition.fieldApiName = event.detail.value;
                condition.isPicklist = type === 'PICKLIST';
                condition.isLookup = type === 'REFERENCE';
                condition.isLWCInput = (type !== 'PICKLIST' && type !== 'REFERENCE');
                let allowedOps = [];
                this.operators.forEach(operator => {
                    if (operator.allowedTypes.includes(type)) {
                        allowedOps.push(operator);
                    }
                });
                condition.operators = allowedOps;
                if (type === 'PICKLIST') {
                    this.conditionOrderWIP = order;
                    this.fieldToBeRetrieved = this.objectName + '.' + event.detail.value;
                }
                else if (type === 'REFERENCE') {
                    this.conditionOrderWIP = order;
                    condition.lookupType = fieldType;

                }
                else {
                    this.fieldToBeRetrieved = '';
                }
            }
        });
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: '$fieldToBeRetrieved' })
    picklistValueRetrieved({ error, data }) {
        if (data) {
            this.conditions.forEach(condition => {
                if (condition.order === parseInt(this.conditionOrderWIP, 10)) {
                    condition.picklistValues = data.values;
                }
            });
        }
        else if (error) {
            this.isError = true;
            this.errorMessage = error.body.message;
        }

    }
    handleOperatorChange(event) {
        let order = event.target.dataset.id;
        this.conditions.forEach(condition => {
            if (condition.order === parseInt(order, 10)) {
                condition.operator = event.detail.value;
            }
        });
    }
    handleFieldValueChange(event) {
        let order = event.target.dataset.id;
        this.conditions.forEach(condition => {
            if (condition.order === parseInt(order, 10)) {
                condition.fieldValue = (condition.type === 'toggle') ? event.target.checked : event.detail.value;
            }
        });

    }

    handleAddClicked() {
        this.conditions.push({ fieldApiName: '', operators: this.operators, fieldValue: '', order: this.conditions.length + 1, type: 'text', isPicklist: false, picklistValues: [], isLookup: false, isLWCInput: true, lookupType: '' });
    }

    handleRemoveClicked(event) {
        let conditionToRemove = event.target.dataset.id;
        this.conditions.splice(conditionToRemove, 1);
    }

    handleRemoveAllClicked() {
        this.conditions = [];
    }

    get colSize() {
        return (this.size === 'MEDIUM' || this.size === 'LARGE') ? 3 : 6;
    }
}