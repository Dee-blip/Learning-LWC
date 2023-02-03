({
	doInit: function(cmp, evt, helper) {
		helper.intializequesType(cmp, evt, helper);
		let obj = [];
		cmp.set('v.sectionList', obj);
		cmp.set('v.isLoading', true);
		let recID = cmp.get('v.recordId');
		let params = { recordId: recID };
		helper.asyncPromisereturn(cmp.get('c.loadWrapper'), { templaRecId: recID }).then(
			function(result) {
				console.log('Intial Wrapper result>>' + result);
				cmp.set('v.sectionList', JSON.parse(result));
				helper.checkSize(cmp, evt, helper, cmp.get('v.sectionList'));
				//nesting Server call since payload is very low it will not create performance issue but kept it seprate mixing up with data wrapper may not look good since data wrapper will have list of values and this will have single value
				helper.asyncPromisereturn(cmp.get('c.intialData'), params).then(
					function(result) {
						var result = JSON.parse(result);
						cmp.set('v.templName', result.templName);
						cmp.set('v.versionNum', result.versionNum);
						cmp.set('v.Disabled', result.disabled);
						cmp.set('v.WriteAccessOfUser', result.writeAccess);
						cmp.set('v.isPublished', result.isPublished);
						cmp.set('v.isLoading', false);
					},
					function(error) {
						cmp.set('v.isLoading', false);
						helper.showToast(cmp, evt, helper, 'Error!', 'error', error);
					}
				);
			},
			function(error) {
				cmp.set('v.isLoading', false);
				helper.showToast(cmp, evt, helper, 'Error!', 'error', error);
			}
		);
	},
	scriptsLoaded: function(component, event, helper) {},
	buttonClick: function(cmp, evt, helper) {
		var localId = evt.getSource().getLocalId();
		console.log('localId>>>' + localId); // Switch for most of button click for Individual func have directly used function
		switch (localId) {
			case 'AddQuestionGroup':
				cmp.set('v.isOpen', true);
				break;
			case 'AddQuestion':
				helper.intializequesType(cmp, evt, helper);
				helper.intializeSections(cmp, evt, helper);
				cmp.set('v.isOpenq', true);
				break;
			case 'AddSecQuestion':
				helper.handleSecQuestions(cmp, evt, helper);
				break;
			case 'createSecId':
				helper.secSave(cmp, evt, helper, '', '');
				break;
			case 'SaveQuestions':
				helper.saveTemplate(cmp, evt, helper);
				break;
			case 'PublishTemplateId':
				helper.saveTemplate(cmp, evt, helper);
				break;
			case 'CloneTemplate':
				helper.reviseTemplate(cmp, evt, helper);
				break;
			default:
				break;
		}
	},
	onsecSave: function(cmp, evt, helper) {
		helper.secSave(cmp, evt, helper, '', '');
	},
	// function is invoked from edit Section button
	editSection: function(cmp, evt, helper) {
		var btnName = evt.getSource().get('v.name');
		var objectList = cmp.get('v.sectionList');
		cmp.set('v.editUniquekey', btnName);
		for (let i = 0; i < objectList.length; i++) {
			if (objectList[i].UniqueName == btnName) {
				cmp.set('v.newGroupname', objectList[i].questionGroup.Name);
				break;
			}
		}
		cmp.set('v.isOpen', true);
	},
	// function is invoked from edit question button ..this takes event button name as unique name compare through list to identify value
	editQues: function(cmp, evt, helper) {
		cmp.set('v.disableSecSelect', true);
		var btnName = evt.getSource().get('v.name');
		var objectList = cmp.get('v.sectionList');
		var objMap = helper.blankObj(cmp, evt, helper);
		cmp.set('v.editquesUniquekey', btnName);
		for (let i = 0; i < objectList.length; i++) {
			for (let k = 0; k < objectList[i].surveyQuestions.length; k++) {
				if (objectList[i].surveyQuestions[k].UniqueName == btnName) {
					objMap.Survey__c = objectList[i].surveyQuestions[k].question.Survey__c;
					objMap.Type__c = objectList[i].surveyQuestions[k].question.Type__c;
					objMap.Question__c = objectList[i].surveyQuestions[k].question.Question__c;
					objMap.Required__c = objectList[i].surveyQuestions[k].question.Required__c;
					objMap.QuestionDescription__c = objectList[i].surveyQuestions[k].question.QuestionDescription__c;
					objMap.Choices__c = objectList[i].surveyQuestions[k].question.Choices__c;
					objMap.OrderNumber__c = objectList[i].surveyQuestions[k].question.OrderNumber__c;
					objMap.Name = objectList[i].surveyQuestions[k].question.Name;
					break;
				}
			}
		}
		cmp.set('v.qQuestion', objMap);
		cmp.set('v.isOpenq', true);
		helper.istypeChange(cmp, evt, helper);
	},

	//invoked when Section is updated
	secUpdate: function(cmp, evt, helper) {
		if (helper.checkfieldValidity(cmp, evt, helper, 'sectionnameId')) {
			var btnName = evt.getSource().get('v.name');
			var objectList = cmp.get('v.sectionList');
			for (let i = 0; i < objectList.length; i++) {
				if (objectList[i].UniqueName == btnName) {
					objectList[i].questionGroup.Name = cmp.get('v.newGroupname');
					break;
				}
			}
			cmp.set('v.editUniquekey', '');
			cmp.set('v.newGroupname', '');
			cmp.set('v.isOpen', false);
			cmp.set('v.sectionList', objectList);
		} else {
			cmp.find('sectionnameId').showHelpMessageIfInvalid();
		}
		helper.checkSize(cmp, evt, helper, cmp.get('v.sectionList'));
	},
	//invoke when sec question is updated
	secquesUpdate: function(cmp, evt, helper) {
		var eRrors = 0;
		var empobjMap = helper.blankObj(cmp, evt, helper);
		var controlAuraId = [ 'questypeId', 'questionId', 'choiceId' ];
		controlAuraId.forEach(function(item, index) {
			eRrors = helper.checkfieldValidity(cmp, evt, helper, item) == true ? eRrors : eRrors + 1;
		});
		if (eRrors !== 0) {
			helper.showToast(
				cmp,
				evt,
				helper,
				'Error!',
				'error',
				'Please complete the mandatory fileds before submitting the question.'
			);
			return;
		}
		var objMap = cmp.get('v.qQuestion');
		var btnName = evt.getSource().get('v.name');
		var objectList = cmp.get('v.sectionList');
		for (let i = 0; i < objectList.length; i++) {
			for (let k = 0; k < objectList[i].surveyQuestions.length; k++) {
				if (objectList[i].surveyQuestions[k].UniqueName == btnName) {
					objectList[i].surveyQuestions[k].question.Survey__c = objMap.Survey__c;
					objectList[i].surveyQuestions[k].question.Type__c = objMap.Type__c;
					objectList[i].surveyQuestions[k].question.Question__c = objMap.Question__c;
					objectList[i].surveyQuestions[k].question.Required__c = objMap.Required__c;
					objectList[i].surveyQuestions[k].question.QuestionDescription__c = objMap.QuestionDescription__c;
					objectList[i].surveyQuestions[k].question.Choices__c = objMap.Choices__c;
					objectList[i].surveyQuestions[k].question.OrderNumber__c = objMap.OrderNumber__c;
					objectList[i].surveyQuestions[k].question.Name = helper.questionToName(objMap.Question__c);
					objectList[i].surveyQuestions[k].choicesObj = helper.stringtoArray(objMap.Choices__c);
					break;
				}
			}
		}
		cmp.set('v.sectionList', objectList);
		cmp.set('v.disableSecSelect', false);
		cmp.set('v.editquesUniquekey', '');
		cmp.set('v.isOpenq', false);
		cmp.set('v.qQuestion', empobjMap);
		helper.checkSize(cmp, evt, helper, cmp.get('v.sectionList'));
	},
	// below JS method delete Section
	deleteSection: function(cmp, evt, helper) {
		var objectList = cmp.get('v.sectionList');
		var listofSecdelete = cmp.get('v.sectDeleteId');
		var btnName = evt.getSource().get('v.name');
		console.log('btnName--' + btnName);
		for (let i = 0; i < objectList.length; i++) {
			if (objectList[i].UniqueName == btnName) {
				if (objectList[i].questionGroup.Id != 'undefined' && !helper.isBlank(objectList[i].questionGroup.Id)) {
					//listofSecdelete.push(objectList[i].questionGroup.Id);
					listofSecdelete = listofSecdelete + ',' + objectList[i].questionGroup.Id;
				}
				objectList.splice(i, 1);
			}
		}
		cmp.set('v.sectionList', objectList);
		cmp.set('v.sectDeleteId', listofSecdelete);
		helper.checkSize(cmp, evt, helper, cmp.get('v.sectionList'));
	},
	// below JS method deletes question from a given section
	deleteQues: function(cmp, evt, helper) {
		var listofquesDelete = cmp.get('v.quesDelete');
		var objectList = cmp.get('v.sectionList');
		var btnName = evt.getSource().get('v.name');
		console.log('len--' + objectList[0].surveyQuestions.length);
		console.log('len-test-' + objectList[0].surveyQuestions.length);
		for (let i = 0; i < objectList.length; i++) {
			for (let k = 0; k < objectList[i].surveyQuestions.length; k++) {
				if (objectList[i].surveyQuestions[k].UniqueName == btnName) {
					if (
						objectList[i].surveyQuestions[k].question.Id != 'undefined' &&
						!helper.isBlank(objectList[i].surveyQuestions[k].question.Id)
					) {
						listofquesDelete = listofquesDelete + ',' + objectList[i].surveyQuestions[k].question.Id;
					}
					objectList[i].surveyQuestions.splice(k, 1);
				}
			}
		}
		cmp.set('v.quesDelete', listofquesDelete);
		cmp.set('v.sectionList', objectList);
		helper.checkSize(cmp, evt, helper, cmp.get('v.sectionList'));
	},
	closeModel: function(cmp, evt, helper) {
		//
		var evtSource = evt.getSource().getLocalId();
		cmp.set('v.' + evtSource, false);
		cmp.set('v.newGroupname', '');
		cmp.set('v.qQuestion', helper.blankObj(cmp, evt, helper));
		cmp.set('v.editUniquekey', '');
		cmp.set('v.editquesUniquekey', '');
		cmp.set('v.disableSecSelect', false);
	},
	typeChange: function(cmp, evt, helper) {
		helper.istypeChange(cmp, evt, helper);
	}
});