function runReport(sel){

  var url = sel.options[sel.selectedIndex].value;

  if(url != "none") {
    sessionStorage.setItem("dayCount", 0);
    location.href = url;
  }
}

function formatDate(offset) {

  var myDate = new Date();
  myDate.setDate(myDate.getDate() - offset);

  var myDateMonth = myDate.getMonth()+1;
  var myDateDay = myDate.getDate();

  if(myDateMonth < 10) {
    myDateMonth = "0" + myDateMonth.toString();
  }

  else {
    myDateMonth = myDateMonth.toString();
  }

  if(myDateDay < 10) {
    myDateDay = "0" + myDateDay.toString();
  }

  else {
    myDateDay = myDateDay.toString();
  }


  return myDate.getFullYear().toString() + myDateMonth + myDateDay;

}

function switchDay(direction) {

  var sessionDay = parseInt(sessionStorage.getItem("dayCount"));

  if(direction == "back") {

    sessionDay = sessionDay + 1;
    sessionStorage.setItem("dayCount", sessionDay);

  }

  if(direction == "fwd") {

    sessionDay = sessionDay - 1;

    if(sessionDay < 0) {

      sessionDay = 0;

    }

    sessionStorage.setItem("dayCount", sessionDay);
  }

  location.reload(true);
}


function chartReset() {

  sessionStorage.setItem("dayCount", 0);
  location.reload(true);

}

