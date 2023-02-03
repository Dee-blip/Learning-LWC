({
	// Generic component Promise to handle server calls
	asyncPromisereturn: function(action, params) {
		return new Promise(
			$A.getCallback(function(resolve, reject) {
				if (params) {
					action.setParams(params);
				}
				action.setCallback(this, function(response) {
					var state = response.getState();
					if (state === 'SUCCESS') {
						resolve(response.getReturnValue());
					} else if (state === 'ERROR') {
						var errors = response.getError();
						if (errors && errors[0] && errors[0].message) {
							reject(errors[0].message);
						}
					} else {
						reject('Unknown Error');
					}
				});
				$A.enqueueAction(action, false);
			})
		);
	},

	secSave: function(cmp, evt, helper, type, id) {
		if (helper.checkfieldValidity(cmp, evt, helper, 'sectionnameId')) {
			if (type == 'Edit') {
				var objectList = cmp.get('v.sectionList');
				for (let i = 0; i < objectList.length; i++) {
					if (objectList[i].UniqueName == id) {
						cmp.set('v.newGroupname', objectList[i].UniqueName);
						objectList[i].questionGroup.Name = cmp.get('v.newGroupname');
					}
				}
				cmp.set('v.sectionList', objectList);
			} else {
				var obj = helper.resetObj(cmp, evt, helper);
				var uniqueId = helper.uniqueNumbergenerator(cmp, evt, helper);
				obj.questionGroup.UniqueName__c = uniqueId;
				obj.UniqueName = uniqueId;
				obj.UniqueNumber = helper.autonUmber(cmp, evt, helper, 'Section');
				obj.questionGroup.Survey__c = cmp.get('v.recordId');
				obj.questionGroup.Name = cmp.get('v.newGroupname');
				obj.questionGroup.Order_Number__c = cmp.get('v.sectionList').length;
				var secObj = cmp.get('v.sectionList');
				secObj.push(obj);
				cmp.set('v.sectionList', secObj);
				cmp.set('v.newGroupname', '');
				cmp.set('v.isOpen', false);
			}
		} else {
			cmp.find('sectionnameId').showHelpMessageIfInvalid();
		}
		helper.checkSize(cmp, evt, helper, cmp.get('v.sectionList'));
	},
	intializequesType: function(cmp, evt, helper) {
		var optionsMap = [];
		let params = {};
		helper.asyncPromisereturn(cmp.get('c.findQuestionType'), params).then(
			function(result) {
				for (var key in result) {
					optionsMap.push({ key: key, value: result[key] });
				}
				cmp.set('v.optionsMap', optionsMap);
				cmp.set('v.isloading', false);
			},
			function(error) {
				cmp.set('v.isloading', false);
			}
		);
	},

	intializeSections: function(cmp, evt, helper) {
		var opts = cmp.get('v.sectionList');
		var secMap = [];
		for (let i = 0; i < opts.length; i++) {
			secMap.push({
				key: opts[i].questionGroup.Name,
				value: opts[i].UniqueName
			});
		}
		// alert(JSON.stringify(secMap));
		cmp.set('v.sectionsMap', secMap);
	},
	//save template at server side
	saveTemplate: function(cmp, evt, helper) {
		if (!cmp.find('templateNameId').get('v.value').trim() > 0) {
			helper.showToast(cmp, evt, helper, 'Error!', 'error', "Template name can't be blank");
			return;
		}
		cmp.set('v.isLoading', true);
		var listofSecdelete = cmp.get('v.sectDeleteId');
		var listofquesDelete = cmp.get('v.quesDelete');
		var evtName = evt.getSource().getLocalId();
		var mainObj = cmp.get('v.sectionList');
		console.log('--listofquesDelete--' + listofquesDelete);
		console.log('--listofSecdelete--' + listofSecdelete);
		var surName = cmp.get('v.templName');
		if (mainObj.length > 0) {
			let params = {
				jsonString: JSON.stringify(mainObj),
				secId: listofSecdelete,
				quesIdList: listofquesDelete,
				surName: surName,
				recId: cmp.get('v.recordId')
			};
			helper.asyncPromisereturn(cmp.get('c.saveTemplate'), params).then(
				function(result) {
					cmp.set('v.enablePublish', true);
					cmp.set('v.sectionList', JSON.parse(result));
					cmp.set('v.sectDeleteId', '');
					cmp.set('v.quesDelete', '');
					if (evtName == 'PublishTemplateId') {
						let params = { recId: cmp.get('v.recordId') };
						helper.asyncPromisereturn(cmp.get('c.publishTemplate'), params).then(
							function(result) {
								var result = JSON.parse(result);
								cmp.set('v.Disabled', result.disabled);
								cmp.set('v.versionNum', result.versionNum);
								cmp.set('v.isPublished', result.isPublished);
								cmp.set('v.isLoading', false);
								helper.showToast(
									cmp,
									evt,
									helper,
									'Success!',
									'success',
									'Template published successfully'
								);
							},
							function(error) {
								cmp.set('v.isLoading', false);
								helper.showToast(cmp, evt, helper, '', 'error', error);
							}
						);
					} else {
						cmp.set('v.isLoading', false);
						helper.showSavebar(cmp, evt, helper);
					}
				},
				function(error) {
					cmp.set('v.isLoading', false);
					helper.showToast(cmp, evt, helper, '', 'error', error);
				}
			);
		} else {
			cmp.set('v.isLoading', false);
			helper.showToast(cmp, evt, helper, '', 'error', 'There is no content to save');
		}
	},
	reviseTemplate: function(cmp, evt, helper) {
		var msg = 'Revising the template will create unpublished version of record,it needs to be published to use.';
		if (!confirm(msg)) {
			return;
		}
		cmp.set('v.isLoading', true);
		helper.asyncPromisereturn(cmp.get('c.reviseTemplate'), { existingRecordId: cmp.get('v.recordId') }).then(
			function(result) {
				helper.navigate(cmp, evt, helper, result);
				cmp.set('v.isLoading', false);
			},
			function(error) {
				cmp.set('v.isLoading', false);
				helper.showToast(cmp, evt, helper, 'Error!', 'error', error);
			}
		);
	},
	handleSecQuestions: function(cmp, evt, helper) {
		var eRrors = 0;
		var emptyMap = helper.blankObj(cmp, evt, helper);
		var controlAuraId = [ 'questypeId', 'questionId', 'questiongroupId', 'choiceId' ];
		controlAuraId.forEach(function(item, index) {
			eRrors =  (helper.checkfieldValidity(cmp,evt,helper,item) == true) ? eRrors : eRrors+1 ;
		});

		if (eRrors == 0) {
			var question = cmp.get('v.qQuestion');
			var mainObj = cmp.get('v.sectionList');
			var surveryObj = helper.resetSurveyobj(cmp, evt, helper);
			var unqieId = helper.uniqueNumbergenerator(cmp, evt, helper);
			surveryObj.UniqueName = unqieId;
			surveryObj.UniqueNumber = helper.autonUmber(cmp, evt, helper, 'Question');
			surveryObj.question.Survey__c = cmp.get('v.recordId');
			surveryObj.question.Name = helper.questionToName(question.Question__c);
			surveryObj.choicesObj = helper.stringtoArray(question.Choices__c);
			surveryObj.question.Choices__c = question.Choices__c;
			surveryObj.question.Required__c = question.Required__c;
			surveryObj.question.Type__c = question.Type__c;
			surveryObj.question.UniqueName__c = unqieId;
			surveryObj.question.Question__c = question.Question__c;
			surveryObj.question.QuestionDescription__c = question.QuestionDescription__c;
			for (let i = 0; i < mainObj.length; i++) {
				if (mainObj[i].UniqueName == question.SectionName) {
					surveryObj.question.OrderNumber__c = mainObj[i].surveyQuestions.length;
					mainObj[i].surveyQuestions.push(surveryObj);
				}
			}
			//	alert(helper.isEquals(mainObj,cmp.get('v.sectionList')));
			cmp.set('v.sectionList', mainObj);
			cmp.set('v.isOpenq', false);
			cmp.set('v.qQuestion', emptyMap);
			//cmp.set('v.isError', false);
		} else {
			helper.showToast(cmp,evt,helper,'Error!','error','Please complete the mandatory field before submitting the question.');
			//cmp.set('v.isError', true);
		}
		helper.checkSize(cmp, evt, helper, cmp.get('v.sectionList'));
	},
	resetObj: function(cmp, evt, helper) {
		var obj = {
			UniqueNumber: null,
			UniqueName: null,
			surveyQuestions: [],
			questionGroup: {
				attributes: {
					type: 'Survey_Question_Group__c'
				},
				Order_Number__c: 0,
				Survey__c: null,
				Name: null,
				UniqueName__c: null
			},
			QuestionCount: 0
		};
		return obj;
	},
	resetSurveyobj: function(cmp, evt, helper) {
		var obj = {
			UniqueNumber: null,
			UniqueName: null,
			question: {
				attributes: {
					type: 'Survey_Question__c'
				},
				Survey__c: null,
				Name: null,
				Choices__c: null,
				Required__c: false,
				Type__c: null,
				UniqueName__c: null,
				Question__c: null,
				QuestionDescription__c: null,
				OrderNumber__c: 0
			},
			choicesObj: [],
			choices: []
		};
		return obj;
	},
	// function to generate unique number
	uniqueNumbergenerator: function(cmp, evt, helper) {
		var dt = new Date().getTime();
		var uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
			var r = ((dt + Math.random() * 16) % 16) | 0;
			dt = Math.floor(dt / 16);
			return (c == 'x' ? r : (r & 0x3) | 0x8).toString(16);
		});
		return uuid;
	},
	// function to convert to obj
	stringtoArray: function(str) {
		var strList = [];
		var returnList = [];
		if (!this.isBlank(str)) {
			strList = str.split('\n');
			for (let i = 0; i < strList.length; i++) {
				if (strList[i] != '') {
					var choiceMap = new Object();
					choiceMap.label = strList[i].trim();
					choiceMap.value = strList[i].trim();
					returnList.push(choiceMap);
				}
			}
		}
		return returnList;
	},
	isBlank: function(str) {
		return !str || /^\s*$/.test(str);
	},
	autonUmber: function(cmp, evt, helper, type) {
		if (type == 'Section') {
			cmp.set('v.sectionUniquenumber', cmp.get('v.sectionUniquenumber') + 1);
			return cmp.get('v.sectionUniquenumber');
		}
		if (type == 'Question') {
			cmp.set('v.questionUniquenumber', cmp.get('v.questionUniquenumber') + 1);
			return cmp.get('v.questionUniquenumber');
		}
		return 0;
	},
	questionToName: function(str) {
		if (str.length < 75) {
			return str;
		} else {
			return str.substr(0, 75) + '...';
		}
	},
	// check questionGroup and Questionsize
	checkSize: function(cmp, evt, helper, obj) {
		cmp.set('v.showSave', false);
		cmp.set('v.showQuestion', false);
		if (obj.length > 0) {
			cmp.set('v.showQuestion', true);
		} else {
			cmp.set('v.showQuestion', false);
		}
		if (obj.length > 0) {
			for (let k = 0; k < obj.length; k++) {
				if (obj[0].surveyQuestions.length > 0) {
					cmp.set('v.showSave', true);
				}
			}
		}
	},
	checkfieldValidity: function(cmp, evt, helper, fieldId) {
		var isValid = false;
		var customValidity = cmp.find(fieldId).get('v.value');
		if (customValidity==null || !customValidity.trim().length > 0) {
			cmp.find(fieldId).set('v.value', '');
		}
		var validity = cmp.find(fieldId).get('v.validity');
		isValid = validity.valid;
		return isValid;
	},
	showSavebar: function(cmp, evt, helper) {
		var date = new Date(); // for now
		var sec;
		if (date.getSeconds() < 10) {
			sec = 0 + date.getSeconds();
		} else {
			sec = date.getSeconds();
		}
		var message = 'Last Saved at ' + date.getHours() + ':' + date.getMinutes() + ':' + sec;
		helper.showToast(cmp, evt, helper, '', 'success', message);
	},
	showToast: function(cmp, evt, helper, title, type, message) {
		var toastEvent = $A.get('e.force:showToast');
		toastEvent.setParams({
			title: title,
			type: type,
			message: message
		});
		toastEvent.fire();
	},
	blankObj: function(cmp, evt, helper) {
		var empobjMap = {
			Survey__c: cmp.get('v.recordId'),
			Name: '',
			Choices__c: '',
			Required__c: false,
			Type__c: '',
			UniqueName__c: '',
			Category__c: '',
			OrderNumber__c: '',
			Question__c: '',
			QuestionDescription__c: '',
			SectionName: ''
		};

		return empobjMap;
	},
	navigate: function(cmp, evt, helper, recordId) {
		var evt = $A.get('e.force:navigateToComponent');
		evt.setParams({
			componentDef: 'c:L2Q_eRSSEditTemplate',
			componentAttributes: {
				recordId: recordId
			}
		});
		evt.fire();
	},
	istypeChange: function(cmp, evt, helper) {
		cmp.find('questypeId').get('v.value') == 'Free Text'
			? cmp.set('v.isFreetext', true)
			: cmp.set('v.isFreetext', false);
	}
});