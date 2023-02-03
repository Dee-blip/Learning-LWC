/* eslint-disable no-eval */
import { LightningElement, wire, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import { publish, MessageContext } from 'lightning/messageService';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';
import hdQuickActionClick from '@salesforce/messageChannel/hdQuickActionClick__c';
import getIncidentDetailsFormatedData from '@salesforce/apex/HD_IncidentHeaderController.getIncidentDetailsFormatedData';
import changeStatusToInProgress from '@salesforce/apex/HD_IncidentHeaderController.changeStatusToInProgress';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import isAccessibleRecord from '@salesforce/apex/HD_ActionMenu_Provider.isAccessibleRecord';
import METADATAID from '@salesforce/label/c.HD_progress';
import Id from '@salesforce/user/Id';
import TASK_OBJECT from '@salesforce/schema/BMCServiceDesk__Task__c';

const METADATA_FIELDS = ['HD_Instance__mdt.MasterLabel', 'HD_Instance__mdt.SettingValue__c', 'HD_Instance__mdt.ChangePicklistColorSettings__c'];

export default class HdHightlightPanel extends NavigationMixin(LightningElement) {
    @api recordId;
    @api flexipageRegionWidth;
    type;
    incidentNumber;
    isSubmittedForApproval;
    @track values;
    isOpen;
    isLoading = true;
    isClone = false;
    userId = Id;
    @track wiredResponse;
    status;
    owner;
    @wire(MessageContext)
    messageContext;
    taskInfo;

    @wire(getObjectInfo, { objectApiName: TASK_OBJECT })
    getTaskInfoCallback(result) {
        this.taskInfo = result.data;
    }

    @api fireRefresh() {
        if (this.isClone) {
            this.isLoading = false;
        }
        else {
            this.isLoading = true;
        }

        if (this.template.querySelector('c-hd_-status_-progress_-indicator')) {
            this.template.querySelector('c-hd_-status_-progress_-indicator').fireRefresh();
        }
        refreshApex(this.wiredResponse);
    }

    metadataId = METADATAID;
    @wire(getRecord, { recordId: '$metadataId', fields: METADATA_FIELDS })
    metadataRecord;

    @wire(isAccessibleRecord, { recordID: '$recordId' })
    hasAccess;

    @wire(getIncidentDetailsFormatedData, { recordId: '$recordId' })
    getIncidetDetails(result) {
        this.wiredResponse = result;
        if (result.data) {
            let metaBeans = [];
            this.type = result.data.incType;
            this.status = result.data.status;
            this.owner = result.data.ownerId;
            this.isSubmittedForApproval = result.data.isSubmittedForApproval;
            this.incidentNumber = (result.data.incType === 'Incident') ? 'IN' + result.data.incidentNumber : 'SR' + result.data.incidentNumber;

            //lableToShow is map of redable message/ lables against the keyValue in json returned from server
            let metaBeansOrder = {
                "priority": "Priority",
                "category": "Category",
                "owner": "Owner",
                "totalEffort": "Time spent",
                "isVipUser": "VIP ticket?",
                "isChild": "Parent Ticket",
                "isParent": "Child Ticket(s)",
                "ccInfo": "CC Users",
                "isAPITicket": "API Created Ticket",
                "hasTask": "Task Progress",
                "status": "Status"
            };
            let keyLookup = {
                "totalEffort": "Time spent"
            };
            for (let key in metaBeansOrder) {
                if (result.data[key]) {
                    let temp = {};
                    temp.label = metaBeansOrder[key];
                    temp.key = result.data[key];
                    if ((key === 'owner' && !result.data.ownerId.startsWith('005')) || key in keyLookup) {
                        temp.class = "float-left slds-m-top_x-small " + key + " " + result.data[key];
                        temp.isText = true;
                        metaBeans.push(temp);
                    } else if (key === 'category') {
                        temp.toolTip = result.data.categoryTree;
                        temp.isTree = true;
                        temp.key = result.data[key];
                        if (result.data.categoryTree) {
                            let items = result.data.categoryTree.split('-->');
                            let hierarchy = [{
                                items: []
                            }];
                            let parser = hierarchy[0];
                            for (let i = items.length - 1; i >= 0; i--) {
                                parser.items = [{ label: items[i], name: items[i], expanded: true, items: [] }];
                                parser = parser.items[0];
                            }
                            parser.items = [{ label: result.data[key], name: result.data[key], expanded: true, items: [] }];
                            temp.items = hierarchy[0].items;
                        }
                        metaBeans.push(temp);
                    } else if (key === 'ccInfo' || key === 'isParent') {
                        let tempItems;
                        let itemIcon;
                        temp.isMultiItems = true;
                        if (key === 'ccInfo') {
                            tempItems = result.data.ccInfo;
                            temp.iconName = 'utility:groups';
                            itemIcon = 'utility:user';
                        }
                        else if (key === 'isParent') {
                            tempItems = result.data.childIncidents;
                            temp.iconName = 'utility:cases';
                            itemIcon = 'utility:case';
                        }

                        let items = [];
                        for (let item in tempItems) {
                            if (item in tempItems) {
                                items = [...items, {
                                    label: tempItems[item],
                                    value: item,
                                    icon: itemIcon
                                }];
                            }
                        }
                        temp.items = items;
                        if (items.length > 0) {
                            metaBeans.push(temp);
                        }

                    } else if (key === 'isChild' || (key === 'owner' && result.data.ownerId.startsWith('005'))) {
                        if (result.data[key]) {
                            temp.isURL = true;
                            if (key === 'isChild') {
                                temp.linkedId = result.data.parentId;
                                temp.linkedName = result.data.parentName;
                                temp.iconName = 'standard:case';
                            }
                            else {
                                temp.linkedId = result.data.ownerId;
                                temp.linkedName = result.data.owner;
                                temp.iconName = 'standard:avatar';
                            }
                            metaBeans.push(temp);
                        }
                    }
                    else if (key === 'hasTask' && result.data[key]) {
                        temp.showProgress = true;
                        let openTaskCount = parseInt(result.data?.openTaskCount, 10);
                        let totalTaskCount = parseInt(result.data?.TaskCount, 10);
                        temp.key = (totalTaskCount - openTaskCount) + '/' + totalTaskCount;
                        temp.progress = Math.round((1 - (openTaskCount / totalTaskCount)) * 100);
                        temp.style = (temp.progress < 10) ? 'top:0.8em;left:0.8em;font-size:smaller' : 'top:0.8em;left:0.4em;font-size:smaller';
                        metaBeans.push(temp);
                    }
                    else if (typeof result.data[key] === 'boolean') {
                        temp.isIcon = true;
                        metaBeans.push(temp);
                    } else {
                        if (key === 'status') {
                            temp.showAdditionalInfo = true;
                        }
                        temp.class = "slds-badge float-left slds-m-top_xxx-small " + key + " " + result.data[key];
                        temp.key = result.data[key];
                        temp.label = metaBeansOrder[key];
                        temp.isText = true;
                        metaBeans.push(temp);
                    }
                }

            }
            this.values = metaBeans;
            this.isLoading = false;
        }
        else if (result.error) {
            this.isLoading = false;
        }
    }

    get showValue() {

        let statusToShowProgress = [];
        let statusToShowAssign = [];
        let allMetadata = [];

        if (this.metadataRecord?.data) {
            allMetadata = this.metadataRecord.data.fields.ChangePicklistColorSettings__c.value.split('#');
            allMetadata.forEach(function (eachData) {
                if (eachData.split('=')[0] === 'Progress') {
                    statusToShowProgress = eachData.split('=')[1];
                }
                else if (eachData.split('=')[0] === 'Assign') {
                    statusToShowAssign = eachData.split('=')[1];
                }
            });
        }

        let mapShowActions = {
            showprogressButton: statusToShowProgress.includes(this.status) ? true : false,
            showAssignToMe: statusToShowAssign.includes(this.status) && (this.userId !== this.owner) && this.hasAccess.data && !this.isSubmittedForApproval ? true : false
        }
        return mapShowActions;
    }

    onHierarchyClick() {
        this.isOpen = !this.isOpen;
    }

    get hierarchyDropdownClass() {
        return (this.isOpen) ? 'slds-dropdown-trigger slds-dropdown-trigger_click slds-m-top_xx-small  slds-is-open' : 'slds-dropdown-trigger slds-m-top_xx-small slds-dropdown-trigger_click';
    }

    onQuickActionClick(event) {
        if (event.target.dataset.id === 'Clone') {
            this.isClone = true;
        }
        else if (event.target.dataset.id !== 'Print' && event.target.dataset.id !== 'NewTask') {
            this.isLoading = true;
        }
        publish(this.messageContext, hdQuickActionClick, { quickAction: event.target.dataset.id });
    }

    gotoParent(event) {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.target.dataset.id,
                actionName: 'view',
            },
        }).then(url => {
            window.open(url);
        });
    }

    get incidentIcon() {
        return (this.type === 'Incident') ? 'standard:case' : 'standard:service_request';
    }

    get showClone() {
        return (this.type === 'Incident') ? true : false;
    }

    get showNewTask() {
        let isTaskAccessible = this.taskInfo?.createable && this.taskInfo?.updateable 
                            && this.taskInfo?.fields?.BMCServiceDesk__dueDateTime__c.createable && this.taskInfo?.fields?.BMCServiceDesk__dueDateTime__c.updateable
                            && this.taskInfo?.fields?.BMCServiceDesk__taskDescription__c.createable && this.taskInfo?.fields?.BMCServiceDesk__taskDescription__c.updateable;
        return isTaskAccessible && this.status !== 'UNASSIGNED' && this.status !== 'CLOSED' && this.status !== 'RESOLVED';
    }

    onMenuItemSelected(event) {
        let recordId = event.detail.value.value;
        if (recordId) {
            // Generate a URL to a User record page
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recordId,
                    actionName: 'view',
                },
            }).then(url => {
                window.open(url);
            });
        }
    }

    showToastError(errorMessage) {
        const event = new ShowToastEvent({
            title: 'Status not changed !',
            message: errorMessage,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    onProgressState() {
        this.isLoading = true;
        changeStatusToInProgress({ recordId: this.recordId })
            .then((result) => {
                if (result !== null) {
                    this.isLoading = false;
                }
                eval("$A.get('e.force:refreshView').fire();");
            })
            .catch((error) => {
                this.isLoading = false;
                this.showToastError(error.body.message);
            })
    }
}