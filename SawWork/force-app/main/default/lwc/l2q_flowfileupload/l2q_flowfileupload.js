/**
 * Author: Rajesh Kumar-GSM Team
 * Description : This component is designed to handle file upload in flow ..which can have functionality of delete/download uploaded files as well as show notification after delete/download.
 * JIRA # :SFDC-6777
 * @todo : Introduce multi file delete functionality (This depends based on business use case as of now it is not required...)
 */
import { LightningElement, api, track } from 'lwc';
import deleteuserFile from '@salesforce/apex/L2Q_PartnerFlowController.deleteuserFile';
import filedownloadLink from '@salesforce/label/c.L2Q_FlowFileDownloadLink';
import getuserDetails from '@salesforce/apex/L2Q_PartnerFlowController.getuserDetails';
import { reduceErrors, isEmpty, returnErrormessage, checkerrtype } from 'c/l2QlwcUtil';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import insertErrorlog from '@salesforce/apex/L2Q_PartnerFlowController.insertErrorlog';

export default class L2q_flowfileupload extends LightningElement {
	/**Begin Component API Specification */
	@api recordId;
	@api allowMultifiles = false;
	@api uploadedFilestring; // this api variable consists data of uploaded files which help in re-initialize uploads when screen flips happens in flow
	@api fileFormat;
	@api deleteAllowed = false;
	@api tableStyle = '';
	@api isFileuploadrequired = false;
	@api deleteconfirmMessage = 'Are you sure you want to delete this file ?';
	@api fileheaderText = 'Upload File';
	@api fileuploadrequiredMessage = ' ';
	@api disabled = false;
	@api hooverText = 'Upload Files';
	@api filedownloadprefixLinked = '';
	/**End Component API Specification */
	/**Begin Component Local Properties */
	uploadedFiles;
	acceptedFormat;
	isloading;
	isshowToast = false;
	filedownloadprefixLinked = '';
	error;
	cusError = { body: { message: '' } };
	isclassicMode = false;
	isclassicError = false;
	/**End Component Local Properties */

	/**Begin Component Lifecycle Hooks */
	constructor() {
		super();
	}
	connectedCallback() {
		// code is handled so connected call back will not have any exceptions
		this.getuserInfo();
		this.uploadedFiles = [];
		this.acceptedFormat = [];
		this.isloading = false;
		this.intializeuploadedFiles(this.uploadedFilestring);
		if (!isEmpty(this.fileFormat)) {
			this.fileFormat.split('#').forEach((el) => {
				this.acceptedFormat.push(el);
			});
		}
	}
	/**End Component Lifecycle Hooks */

	//function to intialize download link
	getuserInfo = () => {
		// this function will not have any exception both from server as well backend
		getuserDetails()
			.then((result) => {
				console.log('getuserInfo >>>' + JSON.stringify(result));
				if (result.usertype.includes('partner')) {
					this.filedownloadprefixLinked = '/partners' + filedownloadLink;
					this.isclassicMode = false;
				} else {
					this.filedownloadprefixLinked = filedownloadLink;
					if (result.uiThemedisplayed == 'theme3') {
						this.isclassicMode = true;
					} else {
						this.isclassicMode = false;
					}
				}
			})
			.catch((error) => {});
	};
	//function to handle re-initialization of files
	intializeuploadedFiles(filedata) {
		if (!isEmpty(filedata)) {
			if (JSON.parse(filedata).length > 0) {
				this.uploadedFiles = JSON.parse(filedata);
			}
		}
	}
	// function to handle when click on done after file upload finish
	handleUploadFinished(event) {
		try {
			this.isloading = true;
			let files = [];
			const uploadedFiles = event.detail.files;
			for (let i = 0; i < uploadedFiles.length; i++) {
				// we can use Array.forEach as well , depends on developer preference :)
				files.push({ fileName: uploadedFiles[i].name, fileId: uploadedFiles[i].documentId });
			}
			this.uploadedFiles = this.uploadedFiles.concat(files);
			this.uploadedFilestring = JSON.stringify(this.uploadedFiles);
			this.isloading = false;
			this.showToast('Success !', 'File uploaded successfully !', 'success', 'dismissable');
			this.isclassicError = false;
		} catch (error) {
			this.handleError(error);
		}
	}
	// handle delete for individual files
	handleDelete(event) {
		let deleteConfirmed = confirm(this.deleteconfirmMessage);
		if (deleteConfirmed) {
			this.deleteFile(event.target.value);
		}
	}
	deleteFile = (fileId) => {
		this.isloading = true;
		deleteuserFile({ documentId: fileId })
			.then((result) => {
				// remove deleted files from file's array
				this.uploadedFiles = this.uploadedFiles.filter((el) => {
					return el.fileId != fileId;
				});
				if (this.uploadedFiles.length > 0) {
					this.uploadedFilestring = JSON.stringify(this.uploadedFiles);
				} else {
					this.uploadedFilestring = '';
				}
				console.log('this.uploadedFilestring >>' + this.uploadedFilestring);
				this.isloading = false;
				this.error = undefined;
				this.showToast('Success !', 'File deleted successfully !', 'success', 'dismissable');
				this.isclassicError = false;
			})
			.catch((error) => {
				this.handleError(error);
			});
	};
	//handle download
	downloadFile(event) {
		let downloadLink = this.filedownloadprefixLinked.split('#');
		console.log('downloadLink>>' + downloadLink);
		window.location.href = downloadLink[0] + event.target.value + downloadLink[1];
	}
	// Hook to Flow's Validation engine if valid then true else false
	@api
	validate() {
		if (this.isFileuploadrequired && this.uploadedFiles.length < 1) {
			return {
				isValid: false,
				errorMessage: this.fileuploadrequiredMessage
			};
		} else {
			return {
				isValid: true
			};
		}
	}
	//function to handles toast Message
	showToast(title, message, variant, mode) {
		this.dispatchEvent(
			new ShowToastEvent({
				title: title,
				message: message,
				variant: variant,
				mode: mode
			})
		);
	}
	hideclassicError() {
		this.isclassicError = false;
	}

	// check if it's custom exception thrown in code else keep existing error
	handleError = (error) => {
		this.isloading = false;
		console.log('Error Details  >>' + JSON.stringify(error));
		if (checkerrtype(error)) {
			let errorDetail = JSON.parse(error.body.message);
			this.cusError.body.message = errorDetail.userMessage;
			this.loggingError(errorDetail.errName, errorDetail.errorsourceName, errorDetail.errorMessage);
		} else {
			this.cusError = error;
		}
		this.error = returnErrormessage(this.cusError);
		if (this.isclassicMode) {
			this.isclassicError = true;
		} else {
			this.showToast('Error', returnErrormessage(this.cusError), 'error', 'sticky');
		}
	};

	// call apex method to log error since this is async promise it will not have any performance impact on UI
	loggingError = (logname, logclass, logmessage) => {
		const recordInput = { logname: logname, logclass: logclass, logmessage: logmessage };
		insertErrorlog(recordInput).then((result) => {}).catch((error) => {
			console.log('Error inserting log : ' + JSON.stringify(error));
		});
	};
}