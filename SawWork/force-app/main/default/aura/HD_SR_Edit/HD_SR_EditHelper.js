({
	helperMethod : function() {

	},

	addInputDetails : function(cmp,helper,resp) {
		var dt_hash =  resp.RD_Inputs;
		var ffinputs = resp.FF_Inputs;
		var ffiValue = resp.FFIValue;
		var add_div = true;
		var current_div = null;
		var column_1 = null;
		var column_2 = null
		console.log(" FFI Value "+ffiValue);

		//Iterate through sr fulfillment inputs
		for(var i=0 ;i < ffinputs.length; i++){

			var ffi = ffinputs[i];
			console.log(" FFI  -- "+ffi.Id+"  -- "+ffi.BMCServiceDesk__Prompt__c+ "  TYPE "+ffi.BMCServiceDesk__ResponseType__c);

			//Handeling display in second column fields
			var el = document.getElementById('input_details');
			var innerHtml = '';
			var name = ffi.Id;

			if(current_div == null && ffi.BMCServiceDesk__ResponseType__c != "Header section"){
				var main_div  = document.createElement('div');
				main_div.id =ffi.Id+"_main";

				column_1 = document.createElement('div');
				column_1.id = ffi.Id+"_col1";
				column_1.style="float:left;padding-left:3%;max-width:49%";

				column_2 = document.createElement('div');
				column_2.id = ffi.Id+"_col2";
				column_2.style="float:left;padding-left: 5%;";
				el.appendChild(main_div);
				main_div.appendChild(column_1);
				main_div.appendChild(column_2);

				current_div = ffi.Id;

				var dummy =  document.createElement('br');
				dummy.style="clear:both;";
				main_div.appendChild(dummy);

			}

			var  parent_div = column_1;
			if(ffi.BMCServiceDesk__DisplayInSecondColumn__c == true){
				parent_div = column_2;
			}


			var infld  = document.createElement('div');
			infld.id = ffi.Id+"_span";
			if(ffi.BMCServiceDesk__Tooltip__c != ''){
				infld.title = ffi.BMCServiceDesk__Tooltip__c || '';
			}
			if(ffi.BMCServiceDesk__Hidden__c == true){
				innerHtml = "";
				innerHtml += " <input type='hidden' id='"+name+"' name='"+name+"' value='"+ffiValue[name]+"' data-type = 'infld'/>" ;
				infld.innerHTML = innerHtml;
				parent_div.appendChild(infld);
				continue;
			}

			//END of  display in second column fields

			var required_html = "<sup style='color:#B22222;font-size:13px;'>*</sup>"
			// Adding different types of fields
			switch (ffi.BMCServiceDesk__ResponseType__c) {
				case "Picklist" :
				console.log(" PICKTEST "+ ffiValue[name])
				var options =  ffi.BMCServiceDesk__InputValues__c.split('П');
                var prompt = ffi.BMCServiceDesk__Prompt__c || "" ;
				innerHtml = "<br/><br/><span id='prompt_"+ffi.Id+"' > <b>"+prompt+"</b></span>&nbsp;&nbsp;<select id='"+name+"' name='"+name+"'  data-type = 'infld' class='slds-input'";
				if(ffi.BMCServiceDesk__AdditionalInfo__c == "1"){
					innerHtml += "  multiple ";
                }

				innerHtml += " >";

				var multi_vals = null;
				if ( ffiValue[name] != null){
					multi_vals = ffiValue[name].split(";");
				}
                if(ffi.BMCServiceDesk__AdditionalInfo__c != "1"){
					innerHtml += " <option value=''>--None--</option> ";
                }
				for( var j= 0 ; j < options.length; j++){
					var val = options[j].split('ф');
					innerHtml += "<option value='"+val[0]+"'";

					if( multi_vals != '' && multi_vals != null){
						for(var mtc = 0 ; mtc < multi_vals.length; mtc++ ){
							if( multi_vals[mtc] == val[0]){
								innerHtml += " selected ";
							}
						}
					}
					innerHtml += ">"+val[0]+"</option>";
				}

				innerHtml += "</select> ";
				infld.innerHTML = innerHtml;
				parent_div.appendChild(infld);
				document.getElementById(ffi.Id).onchange = function(){
					helper.condnl_eval(cmp,ffinputs);
				}
				break;

				case "Radio Button" :
				console.log(" IN Rd BTN -- "+ffi.Id);
				console.log(ffi.BMCServiceDesk__ResponseType__c);
				var options =  ffi.BMCServiceDesk__InputValues__c.split('П');

				innerHtml = "<br/><span id='prompt_"+ffi.Id+"' > <b>"+ffi.BMCServiceDesk__Prompt__c+"</b> </span>";
				innerHtml += "<br> ";
				for( var j= 0 ; j < options.length; j++){
					var val = options[j].split('ф');

         
					innerHtml += " <input type='radio' id='"+name+"_"+j+"' name='"+name+"' value='"+val[0]+"' data-type = 'infld'  ";

					if( ffiValue[name] != null && ffiValue[name] == val[0]){
						innerHtml += " checked ";
					}
					innerHtml += ">"+val[0]+"<br/>";
				}

				innerHtml += "</select> ";
				infld.innerHTML = innerHtml;
				parent_div.appendChild(infld);

				var radios = document.getElementsByName(ffi.Id);
				for(var a = 0; a < radios.length; a++){
					radios[a].onchange = function(){
						helper.condnl_eval(cmp,ffinputs);
					}
				}

				break;
				case "Number":
				innerHtml = "<br/><span id='prompt_"+ffi.Id+"' > <b>"+ffi.BMCServiceDesk__Prompt__c+"</b> </span>&nbsp;&nbsp;";
				innerHtml += " <input type='number' id='"+name+"' name='"+name+"' data-type = 'infld' class='slds-input'";
				if( ffiValue[name] != null ){
					innerHtml += " value='"+ffiValue[name]+"'";
				}
				innerHtml += ">";
				infld.innerHTML = innerHtml;
				parent_div.appendChild(infld);
				break;

				case "Text Field":
				innerHtml = "<br/> <span id='prompt_"+ffi.Id+"' > <b>"+ffi.BMCServiceDesk__Prompt__c+"</b> </span>&nbsp;&nbsp;";
				innerHtml += " <input type='text' id='"+name+"' name='"+name+"' data-type = 'infld' class='slds-input'";
				if( ffiValue[name] != null ){
					innerHtml += " value='"+ffiValue[name]+"'";
				}
				innerHtml += ">";
				infld.innerHTML = innerHtml;
				parent_div.appendChild(infld);
				break;

				case "Date/Time":
				innerHtml = "<br/> <span id='prompt_"+ffi.Id+"' > <b>"+ffi.BMCServiceDesk__Prompt__c+"</b> </span>&nbsp;&nbsp;";
				innerHtml += " <input type='datetime-local' id='"+name+"' name='"+name+"' data-type = 'infld' class='slds-input'";
				if( ffiValue[name] != null ){
					console.log(" DateValue 111 "+ffiValue[name].slice(0,-1));
					innerHtml += " value='"+ffiValue[name].slice(0,-1)+"'";
				}
				innerHtml += ">";
				infld.innerHTML = innerHtml;
				parent_div.appendChild(infld);
				break;

				case "Date":
				innerHtml = "<br/> <span id='prompt_"+ffi.Id+"' > <b>"+ffi.BMCServiceDesk__Prompt__c+"</b> </span>&nbsp;&nbsp;";
				innerHtml += " <input type='date' id='"+name+"' name='"+name+"' data-type = 'infld' class='slds-input'";
				if( ffiValue[name] != null ){
					innerHtml += " value='"+ffiValue[name]+"'";
				}
				innerHtml += ">";
				infld.innerHTML = innerHtml;
				parent_div.appendChild(infld);
				break;

				case "Text Area":
				innerHtml = "<br/> <span id='prompt_"+ffi.Id+"' > <b>"+ffi.BMCServiceDesk__Prompt__c+"</b> </span> &nbsp;&nbsp;";
				innerHtml += " <textarea id='"+name+"' name='"+name+"' data-type = 'infld' class='slds-input'>";
				if( ffiValue[name] != null ){
					innerHtml += ffiValue[name];
				}
				innerHtml += "</textarea>";
				infld.innerHTML = innerHtml;
				parent_div.appendChild(infld);

				break;
				case "Check box":
				innerHtml = "<br/><input type='checkbox' id='"+name+"' name="+name+" value='true' data-type = 'infld' ";

				if( ffiValue[name] != null && ffiValue[name] == 'true'){
					innerHtml += " checked ";
				}
				innerHtml += "> "+ffi.BMCServiceDesk__Prompt__c;
				infld.innerHTML = innerHtml;
				parent_div.appendChild(infld);
				document.getElementById(ffi.Id).onclick = function(){
					helper.condnl_eval(cmp,ffinputs);
				}
				break;
				case "Header Section" :
				console.log(" In Header Section "+ffi.BMCServiceDesk__AdditionalInfo__c);
                    var prompt = ffi.BMCServiceDesk__Prompt__c || '';
				if (ffi.BMCServiceDesk__AdditionalInfo__c == "0"){
					innerHtml = "<br/><b>"+prompt+"</b>"  ;
				}

				if (ffi.BMCServiceDesk__AdditionalInfo__c == "1"){
					innerHtml = "<br/><b><u>"+prompt+"</u></b>"  ;
				}

				if (ffi.BMCServiceDesk__AdditionalInfo__c == "2"){
					innerHtml = "<br/><div style='background-color: lightblue;'><b>"+prompt+"</b></div>"  ;
				}
				innerHtml += " <input type='hidden' id='"+name+"' name='"+name+"' value='header section' data-type = 'infld'/>" ;
				infld.innerHTML = innerHtml;
				el.appendChild(infld);
				add_div = true;
				current_div = null;
				break;

			} //End of switch

			if(ffi.BMCServiceDesk__Required__c == true && ffi.BMCServiceDesk__ResponseType__c != "Check box" ){
				var prmt = document.getElementById('prompt_'+ffi.Id);
				var req = document.createElement('span');
				req.id = 'star_'+ffi.Id;
				//req.style="color:#B22222;font-weight:bold;font-size:20px;";
				prmt.appendChild(req);

				var req_sp = document.getElementById('star_'+ffi.Id);
				req_sp.innerHTML = "<span style='color:#B22222;font-weight:bold;font-size:16px;'>*</span>";

			}

			if(ffi.BMCServiceDesk__URLInfo__c != null && ffi.BMCServiceDesk__URLInfo__c.trim() != ''){
				var urlsp  = document.createElement('span');
				urlsp.id = ffi.Id+"_urlid";
				var ihtml = " &nbsp;&nbsp;<a href='"+ffi.BMCServiceDesk__URLInfo__c+"'><b><i>i</i></b></a>"
				urlsp.innerHTML = ihtml;
				infld.appendChild(urlsp);
			}

		}
	},


	// This eveluate fields display and values depending on stored conditional criteria
	condnl_eval : function(cmp,srDetails) {

		//var srDetails = cmp.get("v.ffi_details");
		console.log("here -- "+srDetails);
		for(var i = 0 ; i < srDetails.length; i++){
			var ffi = srDetails[i];
			console.log(' ----------- START '+ffi.Id+" -- "+ffi.BMCServiceDesk__ResponseType__c);

			if(ffi.BMCServiceDesk__Conditional__c != true){
				continue;
			}

			var cndn_arr =  ffi.BMCServiceDesk__ConditionsPostfix__c.split("¬");
			var last_op = '';

			var cndn_operators = [];
			for(var ni = 0 ; ni < cndn_arr.length; ni++){
				if (cndn_arr[ni] == "AND" || cndn_arr[ni] == "OR"){
					cndn_operators.push(cndn_arr[ni]);
				}
			}

			var eval_value = true;
			console.log("INIT   ID "+ffi.Id+"  --- "+ffi.BMCServiceDesk__Prompt__c+" Ord "+ffi.BMCServiceDesk__Order__c );
			console.log(" CNN "+ffi.Id+" --- "+cndn_arr);
			for(var n = 0 ; n < cndn_arr.length; n++){
				var cn = cndn_arr[n];
				if( cn == "AND" || cn == "OR"){
					continue;
				}

				if (cn == ''){
					continue;
				}

				if( n > 0){
					last_op = cndn_operators[n-1];
				}
				var kval_arr = cn.split("П");
				var var_id = kval_arr[1];
				var condn_val = kval_arr[4];
				var var_type = kval_arr[5];
				var operator = kval_arr[3];

				var elem = document.getElementById(""+var_id+"");
				var fld_val ;
				if( elem != null){
					fld_val = document.getElementById(""+var_id+"").value;
				}

				if ( var_type == "Radio Button") {
					var radios = document.getElementsByName(""+var_id+"");
					for(var b = 0; b < radios.length; b++){
						if(radios[b].checked){
							fld_val = radios[b].value;
						}
					}
				}

				console.log("CNDN ---- "+ffi.Id+" ---"+var_id+"  -- "+fld_val+"  --  "+condn_val);
				var kv_eval = null;

				if( operator == "="){
					if( fld_val == condn_val){
						kv_eval = true;
					}else{
						kv_eval = false;
					}
				}

				if( operator == "!="){
					if( fld_val != condn_val){
						kv_eval = true;
					}else{
						kv_eval = false;
					}
				}

				if (operator == "LIKE" ){
					if(fld_val.includes(condn_val) ){
						kv_eval = true;
					} else{
						kv_eval = false;
					}
				}

				if (operator == "NOT LIKE" ){
					if(fld_val.includes(condn_val) ){
						kv_eval = flase;
					} else{
						kv_eval = true;
					}
				}

				if( last_op != '' && last_op == "AND"){
					eval_value = (kv_eval && eval_value);
				}else if(last_op != '' && last_op == "OR"){
					eval_value = (kv_eval || eval_value);
				}else{

					eval_value = kv_eval ;
				}
				last_op = '';

			}// for n
			var el =  document.getElementById(ffi.Id);

			if(ffi.BMCServiceDesk__Hidden__c == true  ){
				if(eval_value == true){
					var options =  ffi.BMCServiceDesk__InputValues__c.split('П');

					for( var j= 0 ; j < options.length; j++){
						var val = options[j].split('ф');

						if (val[2] == "true"){
							el.value= val[1];
						}

					}
				}else{
					el.value= "";
				}
			}
			// show -hide the input fields depending on criteria evaluation.
			el =  document.getElementById(ffi.Id+"_span");
			console.log("CNDN SHOW "+ffi.Id+" -- "+eval_value);
			var elfld = document.getElementById(""+ffi.Id+"");
			console.log(" -- "+elfld);
			var datatype_val = '';
			if( el != null){
				if(eval_value == false){

					el.style = "display:none";
					datatype_val = '-';    // removes datatype = 'infld' by which input fields are excluded from form submission
					if(elfld != null){
						elfld.value = '';
					}
				}else{
					el.style = "display:block";
					datatype_val = 'infld';

				}
				if(ffi.BMCServiceDesk__Prompt__c == "Radio Button"){
					var x = document.getElementsByName(""+ffi.Id+"");
					var il;
					for (var il = 0; il < x.length; il++) {
						x[il].setAttribute("data-type", datatype_val)
					}
				}else{
					if(elfld != null){
						elfld.setAttribute("data-type", datatype_val);
					}
				}
			}
		}//for i
	},


	//Evaluates and cunstructs parameter values from fulfillment inputs
	save_sr : function(cmp,event) {

		var fd =  cmp.get("v.ffi_details");
		var error_msg = {};


		var inputs = document.getElementById("sredit").querySelectorAll('[data-type="infld"]');

		var inputstr = '';
		var in_hash = {};


		for( var i = 0 ; i < inputs.length ; i++){
			var elem = inputs[i];
			var tp = elem.type;
			console.log(" SEL VAL VAL "+tp+" -- "+elem.name+" -- "+elem.value+" TYpe "+elem.type);
			var usr_val = elem.value;
			switch (tp) {
				case 'radio':
				var options = document.getElementsByName(elem.name);
				for (var k = 0; k < options.length; k++) {
					if (options[k].checked){
						//console.log(' Radio SEL '+options[k].value);
						usr_val = options[k].value;
					}
				}
				break;
				case 'select-one':
				var options =elem.options;
				for (var k = 0; k < options.length; k++) {
					if (options[k].selected){
						console.log(' Radio SEL '+options[k].value);
						usr_val = options[k].value;
					}
				}
				break;
				case 'select-multiple':
				usr_val = "";
				var options = elem.options;
				var ict = 0;
				for (var k = 0; k < options.length; k++) {
					console.log(" Multi "+options[k].value+" SEL = "+options[k].selected);
					if (options[k].selected){
						if(ict > 0){
							usr_val += ";";
						}
						usr_val += options[k].value;
						ict += 1;
					}
				}
				console.log(" Multiple select "+usr_val);
				break;
				case 'checkbox' :
				if(elem.checked == true){
					usr_val = 'true';
				}else{
					usr_val = 'false';
				}
				console.log(" In Checkbox  "+elem.name+" --"+usr_val);
				break;
				case  'text':
				case  'textarea':
				console.log("Text");
				var min_value;
				if (fd[elem.id].BMCServiceDesk__Validate__c == true){
					var txt_length  = usr_val.length;
					var rule_arr = fd[elem.id].BMCServiceDesk__ValidationRule__c.split('=')
					min_value = rule_arr[1];
					if( Number(min_value) >= txt_length){
						error_msg[elem.id] = "Minimum "+min_value+" charectors should be entered"
					}
				}
				break;

				case  'datetime-local':
				usr_val = usr_val+":00Z";
				console.log("DateValue --- "+usr_val);

				break;
				case 'number' :
				console.log("Numberr "+fd[elem.id].BMCServiceDesk__Validate__c);

				if (fd[elem.id].BMCServiceDesk__Validate__c == true){

					var txt_length  = usr_val.length;
					var rule_arr = fd[elem.id].BMCServiceDesk__ValidationRule__c.split('П');
					var condition_value;
					var condn;
					var number_msg = '';
					console.log(" IN NUMBER "+rule_arr+" === "+fd[elem.id].BMCServiceDesk__ValidationRule__c);
					for(var ik =0 ; ik < (rule_arr.length); ik++){
						condn = rule_arr[ik].split("=");
						console.log(" condn 0 "+condn[0]);
						var cndn_0 = condn[0];
						if((condn[0] == "MIN"  && Number(usr_val) < Number(condn[1])) || (condn[0] == "MAX"  && Number(usr_val) > Number(condn[1]))){
							number_msg +=  cndn_0.toLowerCase()+"imum "+ Number(condn[1]);
						}
						if (number_msg != ''){
							error_msg[elem.id] = "Value should be "+number_msg;
						}
					}

				}
				break;
			}//switch

			console.log(" Required -- "+elem.id+"  -- "+fd[elem.id]);
			if(fd[elem.name].BMCServiceDesk__Required__c == true && usr_val == ''){
				error_msg[elem.id] = 'Field cannot be blank';
			}

			if( usr_val != ''){

				in_hash[elem.name] = usr_val;
			}
		}//for inputs.length

		var error = false;
		console.log(" ADDED "+elem.name+" : "+usr_val);
		console.log(" ERROR MSG "+error_msg);

        var field_errors = document.getElementsByClassName("field_error_msg");
        while(field_errors.length > 0){
            field_errors[0].parentNode.removeChild(field_errors[0]);
        }
		for( var err_key in error_msg){
            
            var error_div = document.getElementById(err_key+"_span");         
            var txt_msg = document.createElement('span');
            txt_msg.id = err_key+"_fld_error";
            txt_msg.className = 'field_error_msg';
            error_div.appendChild(txt_msg);
 
			txt_msg.style="color:#FF9494;font-size:11px;font-weight:bold;";
			txt_msg.innerHTML  = "<br/> "+error_msg[err_key];
			error = true;

		}
		if( error == true ){
			return "ERROR";
		}
		console.log(" INPUT HASH "+in_hash);
		cmp.set("v.input_values",in_hash);
		//return inputstr;
	},
    
    handle_error :  function(component,error){
        console.log(" ERR MSG "+error[0].message);
        var dv = document.getElementById("error_div");
        dv.innerHTML = error[0].message;
        dv.style="color:#FF9494;font-size:12px;font-weight:bold;"
    }

})