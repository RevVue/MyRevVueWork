function setFocus() {
	document.getElementById("hiddenElement").focus(); 
}  

function checkedSelectRadio2AmountQtyfrom1() {
	if(document.getElementById("page:form:pbs2:selectr1:0").checked)
		document.getElementById("page:form:pbs2:selectr2:0").checked = true;
	else { 
		document.getElementById("page:form:pbs2:selectr2:0").checked = false;

}  

if(document.getElementById("page:form:pbs2:selectr1:1").checked) {
	document.getElementById("page:form:pbs2:selectr2:1").checked = true;
}
else
	document.getElementById("page:form:pbs2:selectr2:1").checked = false;
}

function checkedSelectRadio1AmountQtyfrom2() {

if(document.getElementById("page:form:pbs2:selectr2:0").checked)
	document.getElementById("page:form:pbs2:selectr1:0").checked = true;
else {
	document.getElementById("page:form:pbs2:selectr1:0").checked = false;
}

if(document.getElementById("page:form:pbs2:selectr2:1").checked) {
	document.getElementById("page:form:pbs2:selectr1:1").checked = true;
} 
else 
	document.getElementById("page:form:pbs2:selectr1:1").checked = false;
}

function saveMileStone() {           
	saveMiles();
}

function saveAMMileStone() {
	saveAMMiles();
}

function saveAMMileStoneActual() {
	saveAMMiles();
}

//This method is used on Remove category button onclick
function checkSelected(listSize , type, isSplit) {

	//Checking for the list size
	if(listSize == 0) {
		alert('No any category available to remove.');
	}else {

		//Variables 
		/** var preFix = '';
		var suffix = '';
		var counter = 0;

		if(type == 'Blended Revenue' && isSplit != 'Split') {
			preFix = 'page:form:pbs2:repet1:';
			suffix = ':firstChkbox';
		}else if(type == 'Milestone') {

			preFix = 'page:form:pbs2:repet:';
			suffix = ':firstCheckbox';
		} else if(type == 'Blended Revenue' && isSplit == 'Split') {
			preFix = 'page:form:pbs2:repet2:';
			suffix = ':firstChkbox1';
		}

		//Loop over wrapper size
		for(i =0; i < parseInt(listSize) ; i++) {
			var idP = preFix + i + suffix;
			//Checking for selected value
			if(document.getElementById(idP).checked == true)
				counter = 1;
		} **/
		//Calling remove category method
		//Checking for conditions
		if(type == 'Blended Revenue' && isSplit != 'Split') 
			removeCat();
		else if(type == 'Milestone') 
			removeMile();
		else if(type == 'Blended Revenue' && isSplit == 'Split') 
			removeSplitCat();

		return true;
	}
}

//This method is used on Add category button onClick
function checkSelected1(listSize, type, isSplit) {

	if(listSize == 0) {
		if(type == 'Blended Revenue' && isSplit != 'Split') 
			addCat();
		else if(type == 'Milestone') 
			addMile();
		else if (type == 'Blended Revenue' && isSplit == 'Split') 
			addSplitCat();

	}else {

		//Variables 
		/** var preFix = '';
		var suffix = '';
		var counter = 0;

		if(type == 'Blended Revenue'  && isSplit != 'Split') {
			preFix = 'page:form:pbs2:repet1:';
			suffix = ':firstChkbox';	
		}else if(type == 'Milestone') {
			preFix = 'page:form:pbs2:repet:';
			suffix = ':firstCheckbox';
		} else if(type == 'Blended Revenue' && isSplit == 'Split') {
			preFix = 'page:form:pbs2:repet2:';
			suffix = ':firstChkbox1';
		}			

		for(i =0; i < parseInt(listSize) ; i++) {

			var idP = preFix + i + suffix;
			if(document.getElementById(idP).checked == true)
			counter = 1;
		} **/
		
		if(type == 'Blended Revenue' && isSplit != 'Split')
			addCat();
		else if(type == 'Milestone') 
			addMile();
		else if (type == 'Blended Revenue' && isSplit == 'Split')
			addSplitCat();

		return true;
		
	}
}

//This method is used to delete the categories
function checkForDetele() {
	var indexString = '';
	$('#table1').find('tr').each(function(){
		if($(this).find('.isDelete').is(':checked')) {
			indexString += $(this).find('.isDelete').parent().attr('deleteIndex') + ',';
		}
	});		
	document.getElementById('page:form:indexStringId').value = indexString; 
} 

//This method is used to open popup window
function showSplitPopup(row) {

	$("#page\\:form\\:pbs2\\:splitDiv").show();	 
	$("#blockUIDiv").show();

	$(".ui-icon-closethick").bind('click', function() {
		$("#blockUIDiv").hide();
		$("#page\\:form\\:pbs2\\:splitDiv").dialog("close");

	});
}

function closePopUp() {
	$("#blockUIDiv").hide();
	$("#page\\:form\\:pbs2\\:splitDiv").hide();
}

//This function is used to validate the amount on split screen
function saveSplitJS(listsize, originalamount) {

	//Getting recognized and deferred amount
	var totalRec = document.getElementById('page:form:pbs2:splitOp1').textContent;
	var totalDef = document.getElementById('page:form:pbs2:splitOp2').textContent;

	//Format amount 
	totalRec = totalRec.replace(',' , '');
	totalDef = totalDef.replace(',', '');
	totalRec = parseFloat(totalRec).toFixed(2);
	totalDef = parseFloat(totalDef).toFixed(2);

	//Add
	var amount = (parseFloat(totalRec) + parseFloat(totalDef)).toFixed(2);

	//Checking for the conditions and show alert
	if(amount > originalamount) 
		alert('Sum of split amount should not be greater than Parent amount .');
	else if(amount < originalamount) 
		alert('Sum of split amount should not be lesser than Parent amount . ' );
	else if(amount = originalamount)
		saveSplitsMethod();   

	return false;	
}

function saveRule(listSize , ruleType) {
				
	//Checking for Rule = Blended 
	if(ruleType == 'Blended Revenue') {

		var isSuccess = true;
		var prefix = "page:form:pbs2:repet1:";
		var suffix = ":blndCatName";
		
		for(i =0; i <= parseInt(listSize) ; i++) {
			var idP = prefix + i + suffix;
			var inputVal = document.getElementById(idP);
			if(inputVal != null && inputVal != 'undefined') {
				inputVal = inputVal.value;
				if(inputVal == '') 
					isSuccess = false;
			}
		}
		if(isSuccess)
			saveAllRules();
		else {
			alert('Please enter name for all categories.') ;
			return ;
		}
	}else 
		saveAllRules();
}
