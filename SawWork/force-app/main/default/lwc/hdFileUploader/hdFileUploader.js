import { LightningElement, track, api } from "lwc";
import saveAttachments from "@salesforce/apex/HD_lwcUtilityClass.saveAttachments";

export default class HdFileUploader extends LightningElement {
  @track state = {
    filesUploaded: [],
    fileCount: 0,
    fileMessage: "",
    totalFileSize: 0,
    toolTipMessage: "",
    fileNames: []
  };

  @api maxFileSize = 1000000;
  @api maxFiles = 1;

  set toolTipMessage(message){
    this.state.toolTipMessage = message;
  }

  get toolTipMessage(){
    return this.state.toolTipMessage;
  }

  connectedCallback(){
    this.toolTipMessage = "Please select multiple files at once: Max " + this.maxFiles + " files: Total " + (this.maxFileSize/1000000).toFixed(1) + " MB";
  }

  handleFilesChange(event) {
    if (
      event.target.files.length > 0 &&
      event.target.files.length <= this.maxFiles
    ) {
      let fileSize = 0;
      let fileNames = [];
      for (let i = 0; i < event.target.files.length; i++) {
        fileNames.push(event.target.files[i].name);
        fileSize = fileSize + event.target.files[i].size;
      }
      this.state.fileNames = [...fileNames];
      this.state.totalFileSize = fileSize;
      if (this.state.totalFileSize > this.maxFileSize) {
        this.fileMessage = "ERROR: file size is too large. LIMIT: " + (this.maxFileSize/1000000).toFixed(1) + " MB";
      } else {
        let files = event.target.files;
        this.state.filesUploaded = [...files];
        this.state.fileCount = event.target.files.length;
        this.fileMessage = this.state.fileCount + " of " + this.maxFiles + " Files: " + (this.state.totalFileSize/1000000).toFixed(1) + " MB.";
        this.toolTipMessage = this.state.fileNames.join(': ');
        //remove this before moving qa
        //this.uploadHelper("a5U3C000000AEXXUA4");
      }
    } else {
      this.fileMessage = "ERROR: Maximum " + this.maxFiles + " files allowed";
    }
  }

  set fileMessage(message) {
    this.state.fileMessage = message;
  }

  get fileMessage() {
    return this.state.fileMessage;
  }

  @api uploadHelper(parentRecordId) {
    return new Promise((resolve,reject) => {
        if(this.state.fileCount === 0){
            resolve("No files added");
        }
    var promiseList = [];

    this.state.filesUploaded.forEach((file,index) =>{
        let promise = this.fileReadHelper(parentRecordId,file,index);
        promiseList = [...promiseList, promise];
    });

    Promise.all(promiseList)
    .then(fileList=>{
        return saveAttachments({attachmentList:fileList});
    })
    .then(result =>{
        resolve(result);
    })
    .catch(error =>{
        reject(error);
    });
});
  }

  fileReadHelper(ParentRecordId,file,index) {
    return new Promise((resolve, reject) => {
      let fileReader = new FileReader();

      fileReader.onload = () => {
        let fields = {};
        var fileContent = fileReader.result;
        var base64 = "base64,";
        var content = fileContent.indexOf(base64) + base64.length;
        fileContent = fileContent.substring(content);
        fileContent = encodeURIComponent(fileContent);

        fields["idParent"] = ParentRecordId;
        fields["strFileName"] = file.name;
        fields["base64data"] = fileContent;
        resolve(JSON.stringify(fields));
        }

        fileReader.onerror = () =>{
          reject(fileReader.error);
        }

      fileReader.readAsDataURL(file);
    });
  }
}