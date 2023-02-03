/*JS File for External Survey Functionality*/
		

        $( document ).ready(function() {            
            if(customerRespondedJS){
                document.getElementById('successMessageId').style.display = "block";
                document.getElementById('successMessageId').scrollIntoView();
                document.querySelectorAll("[id$=masterFieldSetId]")[0].setAttribute('disabled','true');
            }
            else if(invalidFormJS){
                document.getElementById('invalidFormId').style.display = "block";
            }
        });

        function validateRequiredFields(){
            var allRequiredQuestion = document.querySelectorAll("[id$=RequiredQues]");

            for(var i = 0 ; i < allRequiredQuestion.length ; i++){
                var masterDivId = allRequiredQuestion[i].id;
                var divIdToDisplayError = 'masterDiv' + masterDivId.substring(0,masterDivId.indexOf("RequiredQues"));
                var errorMessageId = masterDivId.substring(0,masterDivId.indexOf("RequiredQues")) + 'errorMessage';
	            if(masterDivId.toLowerCase().indexOf("checkbox") !== -1){
    	            validateRequiredCheckbox(allRequiredQuestion[i],false,divIdToDisplayError,errorMessageId);
                }
                else if(allRequiredQuestion[i].id.toLowerCase().indexOf("radio") !== -1){
                    validateRequiredRadioButton(allRequiredQuestion[i],false,divIdToDisplayError,errorMessageId);
                }
                else if(allRequiredQuestion[i].id.toLowerCase().indexOf("text") !== -1){
                    validateTextBox(allRequiredQuestion[i],false,divIdToDisplayError,errorMessageId);
                }
                else if(allRequiredQuestion[i].id.toLowerCase().indexOf("picklist") !== -1){
                    validateRequiredPicklist(allRequiredQuestion[i],false,divIdToDisplayError,errorMessageId);
                }
            }

            if(divToScroll !== ''){
                document.getElementById(divToScroll).scrollIntoView();
                divToScroll='';
            }
            else{
                submitForm();
                document.querySelectorAll("[id$=masterFieldSetId]")[0].setAttribute('disabled','true');
            }

        }

        function showSuccessMessage(){
            $('#thankYouModal').modal('show');
            document.getElementById('successMessageId').style.display = "block";
            document.getElementById('successMessageId').scrollIntoView();
        }

        function validateIndividualField(masterDivId){

            if(masterDivId.toLowerCase().indexOf('requiredques') !== -1){
                var divIdToDisplayError = 'masterDiv' + masterDivId.substring(0,masterDivId.indexOf("RequiredQues"));
                var errorMessageId = masterDivId.substring(0,masterDivId.indexOf("RequiredQues")) + 'errorMessage';
                var divToValidate = document.getElementById(masterDivId);
                if(masterDivId.toLowerCase().indexOf("checkbox") !== -1){
    	            validateRequiredCheckbox(divToValidate,true,divIdToDisplayError,errorMessageId);
                }
                else if(masterDivId.toLowerCase().indexOf("radio") !== -1){
                    validateRequiredRadioButton(divToValidate,true,divIdToDisplayError,errorMessageId);
                }
                else if(masterDivId.toLowerCase().indexOf("text") !== -1){
                    validateTextBox(divToValidate,true,divIdToDisplayError,errorMessageId);
                }
                else if(masterDivId.toLowerCase().indexOf("picklist") !== -1){
                    validateRequiredPicklist(divToValidate,true,divIdToDisplayError,errorMessageId);
                }
            }
        }

        function validateRequiredRadioButton(requiredRadioButton, radioButtonId,divIdToDisplayError,errorMessageId){
            var radioButtonValues = requiredRadioButton.getElementsByTagName('input');
            var displayError = true;
            for(var i = 0; i < radioButtonValues.length; i++){
                if(radioButtonValues[i].checked){
                    displayError = false;
                    break;
                }
            }

            displayErrorForRequiredField(displayError,divIdToDisplayError,errorMessageId);
        }

        function validateTextBox(requiredTextBox, textBoxId,divIdToDisplayError,errorMessageId){
            var textBoxValues = requiredTextBox.getElementsByTagName('textarea');
            var displayError = true;
            for(var i = 0; i < textBoxValues.length; i++){
                if(textBoxValues[i].value.trim() === ''){
                    displayError = true;
                    break;
                }
                else{
                    displayError = false;
                }

            }
            displayErrorForRequiredField(displayError,divIdToDisplayError,errorMessageId);
        }

        function validateRequiredPicklist(requiredPicklist, picklistId,divIdToDisplayError,errorMessageId){
            var picklistValues = requiredPicklist.getElementsByTagName('option');
            var displayError = true;
            for(var i = 0; i < picklistValues.length; i++){
                if(picklistValues[i].selected && picklistValues[i].value != 'None'){
                    displayError = false;
                    break;
                }

            }
            displayErrorForRequiredField(displayError,divIdToDisplayError,errorMessageId);
        }


        function validateRequiredCheckbox(requiredCheckbox, checkboxId, divIdToDisplayError, errorMessageId){
            var checkboxValues = requiredCheckbox.getElementsByTagName('input');
            var displayError = true;
            for(var i = 0; i < checkboxValues.length; i++){
                if(checkboxValues[i].checked){
                    displayError = false;
                    break;
                }
            }

            displayErrorForRequiredField(displayError,divIdToDisplayError,errorMessageId);

        }

        function displayErrorForRequiredField(displayError,divIdToDisplayError,errorMessageId){
            if(displayError){
                document.getElementById(divIdToDisplayError).style.backgroundColor = "#ffe6eb";
                document.getElementById(errorMessageId).style.display = "block";
                if(divToScroll===''){
                    divToScroll = divIdToDisplayError;
                }
            }
            else{
                document.getElementById(divIdToDisplayError).style.backgroundColor = "white";
                document.getElementById(errorMessageId).style.display = "none";
            }
        }