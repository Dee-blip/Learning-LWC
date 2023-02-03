/* eslint -- disable guard -- for -- in */
import { LightningElement, track, wire } from 'lwc';
import upsertServiceRequest from '@salesforce/apex/HD_RequestDefinitionManager.upsertServiceRequest';
import getRequestDefinitions from '@salesforce/apex/HD_RequestDefinitionManager.getAllRequestDefinitions';
import generateJSON from '@salesforce/apex/HD_RequestDefinitionManager.generateJSON';
import readSampleJSON from '@salesforce/apex/HD_RequestDefinitionManager.readSampleJSON';

export default class HdRequestDefinitionManager extends LightningElement {
    @track state = {
        fileName : '',
        showLoadingSpinner : false,
        items : [],
        filesUploaded : [],
        fileContents : '',
        statusMessage:'',
        errors:'',
        activeSections:['Step1','Step2','Step3'],
        iconName:'',
        selectedRequestDefn:'',
        requestDefns:[],
        sampleJSONContents:'',
        btnIconName:'action:clone',
        hoverTextCopyButton: 'Copy to Clipboard' 
    };
    MAX_FILE_SIZE = 6000000;
    
    @wire(getRequestDefinitions)
    getRequestDefnCallback({error, data}) {
        if(data) {
            let defns = [];
            data.forEach((item) => {
                defns = [...defns,{label:item.Name, value:item.Id}];
            })
            this.state.requestDefns = [...defns];
        }
        else if(error) {
            this.state.iconName ='action:close';
            this.state.statusMessage = error.body.message;
            this.state.errors = error.body.stackTrace;
        }
    }

    // getting file 
    handleFilesChange(event) {
        if(event.target.files.length > 0) {
            this.state.filesUploaded = event.target.files;
            this.state.fileName = event.target.files[0].name;
        }
        if(this.state.filesUploaded.length > 0) {
            this.uploadHelper();
        }
        else {
            this.state.fileName = 'Please select file to upload!!';
        }
    }

    handleUpsert() {
        this.state.showLoadingSpinner = true;
        upsertServiceRequest({ fileContents: this.state.fileContents})
        .then(result => {
            this.handleSuccess(this.state.fileName + '  --  Uploaded Successfully!!!');
            this.state.showLoadingSpinner = false;
        })
        .catch(error => {
            this.handleError(error);
            this.state.showLoadingSpinner = false;
        });
    }

    handleGenerate() {
        this.state.showLoadingSpinner = true;
        generateJSON({ requestDefnId: this.state.selectedRequestDefn})
        .then(result => {
            this.state.fileContents = JSON.stringify(this.modifyJSON(result, {}), null, 4);
            this.createTreeModel();
            this.handleSuccess('JSON generated successfully!!');
            this.state.showLoadingSpinner = false;
        })
        .catch(error => {
            this.handleError(error);
            this.state.showLoadingSpinner = false;
        });
    }

    modifyJSON(result, reqDefn) {
        for(let key in result) {
            if(!(result[key] instanceof Array)) {
                if(key !== 'Id' && key !== 'BMCServiceDesk__FKRequestDefinition__c') {
                    reqDefn[key] = result[key];
                }
            }
            else {
                reqDefn[key] = {totalSize:result[key].length, done:true, records:[]};
                result[key].forEach((item) => {
                    reqDefn[key].records = [...reqDefn[key].records,this.modifyJSON(item, {})];
                });
            }
        }
        return reqDefn;
    }

    uploadHelper() {
        const file = this.state.filesUploaded[0];
       if (file.size > this.MAX_FILE_SIZE) {
            window.console.log('File Size is to long');
            return ;
        }
        
        // create a FileReader object 
        const fileReader= new FileReader();
        //set onload function of FileReader object  
        fileReader.onloadend = (() => {
            this.state.fileContents = fileReader.result;
            this.createTreeModel();
        });
        fileReader.readAsText(file);
    }

    createTreeModel() {
        if(this.state.fileContents) {
            const item = JSON.parse(this.state.fileContents);
            let tree = [...[{label:"Service Request Definition", name:"Service Request Definition", isExpanded:false, items:[]}]];
            this.createTreeViewNode(item, tree[0]);
            this.state.items = [...tree];
        }
    }

    createTreeViewNode(node, tree) {
        if(node instanceof Array) {
            node.forEach(item => {
                const itemProps = Object.keys(item);
                let subTree;
                if(itemProps.includes('BMCServiceDesk__Prompt__c') && itemProps.includes('BMCServiceDesk__Order__c')) {
                    subTree = {label:item.BMCServiceDesk__Order__c +' - '+ item.BMCServiceDesk__Prompt__c, name:item.BMCServiceDesk__Prompt__c,isExpanded:false, items :[]};
                }
                else {
                    subTree = {label:'Obj', name:'Obj',isExpanded:false, items :[]};
                }
                tree.items = [...tree.items, subTree];
                this.createTreeViewNode(item, subTree);
            });
        }
        else if(node instanceof Object) {
            const itemProps = Object.keys(node);
            itemProps.forEach((property) => {
                if(!(node[property] instanceof Object)) {
                    if(property.includes('BMC') || property.includes('Name')) {
                        tree.items.push({label:property+' - '+node[property], name:property,isExpanded:false});
                    }
                    return tree;
                }
                const subTree = {label:property, name:property,isExpanded:false, items :[]};
                tree.items = [...tree.items, subTree];
                this.createTreeViewNode(node[property], subTree);
            });
        }
    }

    onRequestDefinitionChanged(event) {
        this.state.selectedRequestDefn = event.target.value;
    }

    handleSuccess(message) {
        this.state.showLoadingSpinner = false;
        this.state.iconName ='action:approval';
        this.state.statusMessage = message;
    }

    handleError(error) {
        this.state.iconName ='action:close';
        if(error.body) {
            if(error.body.message) {
                this.state.statusMessage = error.body.message;
            }
            if(error.body.stackTrace) {
                this.state.errors = error.body.stackTrace;
            }
        }
    }

    get isFileNotSelected() {
        return (this.state.fileContents)?false:true;
    }

    showModal(){
        if(!this.state.sampleJSONContents){
            this.state.showLoadingSpinner = true;
            readSampleJSON({ filename: 'Test_Service_Request_Defn'})
            .then(result => {
                this.state.sampleJSONContents = JSON.stringify(this.modifyJSON(result, {}), null, 4);
                this.state.showLoadingSpinner = false;
            })
            .catch(error => {
                this.handleError(error);
                this.state.showLoadingSpinner = false;
            });
        }
        else{
            // This is the workaround to retrigger the bindings as the popup is added to the DOM after closing.
            let tempContents = this.state.sampleJSONContents;
            this.state.sampleJSONContents = '';
            this.state.sampleJSONContents = tempContents;
            
        }
        this.template.querySelector('c-hd-Modal-Popup').open();

    }

    closeModal(){
        this.template.querySelector('c-hd-Modal-Popup').close();
    }

    copyToClipboard(){
        let copyMe = this.template.querySelector('[data-id="txtJson"]');
        copyMe.select();
        document.execCommand('copy');
        this.state.btnIconName = 'action:approval';
        this.state.hoverTextCopyButton = 'Copied'
        setTimeout(() => { 
            this.state.btnIconName = 'action:clone';
            this.state.hoverTextCopyButton = 'Copy to Clipboard'
        }, 3000);
    }
}