var currentPage = 1;

function checkScroll() {
  if (nearBottomOfPage()) {
   $.ajax({ //other options here
      complete: function () {

      new_image = $("#render_show_images img").last().clone(); 
      path = new_image.attr("src");
      new_image.attr("style","");
      var myRegexp = /\??(.*)pages=(\d*)(;?.*)/;
      var match = myRegexp.exec(path);

      if( match === null ){
        path = path + "?pages=2"
        new_image.attr("id", new_image.attr("id") + 2);
      }else{
        path = path.replace(myRegexp, RegExp.$1 + "pages=" + ( 1 + parseInt(RegExp.$2))  + RegExp.$3);
        
        id = new_image.attr("id");
        reg = /([^0-9]*)([0-9]*)$/;
        mat = reg.exec(id);
        if(mat !== null){
          if(mat.length){
            id = mat[1] + (parseInt(mat[2]) + 1);
          }else{
            id = id + "2";
          }
        }
        new_image.attr("id", id);
      }
      new_image.attr("src", path);  // change image back when ajax request is complete

      $("#render_show_images").append(new_image);
      setTimeout("$(document).ready(function(){ checkScroll(); });",3000);
    } });
  } else {
    setTimeout("checkScroll()", 250);
  }
}

function nearBottomOfPage() {
  return scrollDistanceFromBottom() < 20;
}

function scrollDistanceFromBottom(argument) {
  return pageHeight() - (window.pageYOffset + self.innerHeight);
}

function pageHeight() {
  return Math.max(document.body.scrollHeight, document.body.offsetHeight);
}

$(document).ready(function(){ checkScroll(); });