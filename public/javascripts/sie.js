/*SIE-SVG without Plugin under LGPL2.1 & GPL2.0 & Mozilla Public Lisence
 *公式ページは http://sie.sourceforge.jp/
 *利用方法は <script defer="defer" type="text/javascript" src="sie.js"></script>
 */
/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the Mozilla SVG Cairo Renderer project.
 *
 * The Initial Developer of the Original Code is IBM Corporation.
 * Portions created by the Initial Developer are Copyright (C) 2004
 * the Initial Developer. All Rights Reserved.
 *
 * Parts of this file contain code derived from the following files(s)
 * of the Mozilla SVG project (these parts are Copyright (C) by their
 * respective copyright-holders):
 *    layout/svg/renderer/src/libart/nsSVGLibartBPathBuilder.cpp
 *
 * Contributor(s):DHRNAME revulo
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either of the GNU General Public License Version 2 or later (the "GPL"),
 * or the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */

//これを頭に付けたら、内部処理用
var  NAIBU = {};
//documentを速くするために
/*@cc_on  _d=document;eval('var  document=_d')@*/
//bookmarkletから呼び出されたらtrue
var sieb_s;

//svgtovml load時に、最初に起動する関数
function svgtovml() {
  //IEだったらtrueを返す
  var isMSIE = /*@cc_on!@*/false;
  //引数にtrueがあれば、例外処理のログを作動させる
  stlog = new STLog(false);
  var ary = document.getElementsByTagName("script");
  //全script要素をチェックして、type属性がimage/svg+xmlならば、中身をSVGとして処理する
  for (var i=0; i < ary.length; i++) {
    var hoge = ary[i].type;
    if (ary[i].type === "image/svg+xml") {
      var ait = ary[i].text;
      if (sieb_s && ait.match(/&lt;svg/)) {
        //ソース内のタグを除去
        ait = ait.replace(/<.+?>/g, "");
        //エンティティを文字に戻す
        ait = ait.replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, '"').replace(/&amp;/g, "&");
      }
      if (isMSIE) {
        setVMLNameSpace();
        var da = {};
        da.obj = []; da.obj[i] = ary[i]; da.num = i + 1; da.content = ait.replace(/\shref=/g, " target='_top' xlink:href="); da.success = true;
        ca(da);
      } else {
        var base = location.href.replace(/\/[^\/]+?$/,"/"); //URIの最後尾にあるファイル名は消す。例: /n/sie.js -> /n/
        ait = ait.replace(/\shref=(['"a-z]+?):\/\//g, " target='_top' xlink:href=$1://").replace(/\shref=(.)/g, " target='_top' xlink:href=$1"+base);
        var s = textToSVG(ait,ary[i].getAttribute("width"),ary[i].getAttribute("height"));
        ary[i].parentNode.insertBefore(s,ary[i]);
      }
    }
  }
  NAIBU.STObject = new Objectembeds();
  if (isMSIE) {
    setVMLNameSpace();
    var oba = document.createElement("div");
    oba.setAttribute("id","_NAIBU_outline");
    document.body.appendChild(oba);
    NAIBU.STObject.next();
    success = true;
  } else if (/a/[-1] === 'a'){ //Firefoxだったらtrueを返す
    NAIBU.STObject.ffnext();
  }
}
//他のページに移動する際に起動
function unsvgtovml() {
  NAIBU = stlog = STLog = null;
}

//vmlの名前空間をセット（必須）
function setVMLNameSpace() {
  if (!document.namespaces["v"]) {
    document.namespaces.add("v","urn:schemas-microsoft-com:vml");
    document.namespaces.add("o","urn:schemas-microsoft-com:office:office");
    var st = document.createStyleSheet();
    var vmlUrl = "behavior: url(#default#VML);display:inline-block;} "; //inline-blockはIEのバグ対策
    st.cssText = "v\\:rect{" +vmlUrl+ "v\\:image{" +vmlUrl+ "v\\:fill{" +vmlUrl+ "v\\:stroke{" +vmlUrl+ "o\\:opacity2{" +vmlUrl
      + "dn\\:defs{display:none}"
      + "v\\:group{text-indent:0px;position:relative;width:100%;height:100%;" +vmlUrl
      + "v\\:shape{width:100%;height:100%;" +vmlUrl;
  }
}

//windowに指定したイベントと関数を追加
NAIBU.addEvent = function(evt,lis){
  if (window.addEventListener) {
    window.addEventListener(evt, lis, false);
  } else if (window.attachEvent) {
    window.attachEvent('on'+evt, lis);
  } else {
    window['on'+evt] = lis;
  }
}
NAIBU.addEvent("load",svgtovml);
NAIBU.addEvent("unload",unsvgtovml);

//以下は例外処理のログをとるためのもの。開発者以外は削除すること
function STLog(jou) {
this.jo = jou;
if (this.jo) {
  this.p = document.createElement("div");
  this.p.innerHTML = "<h1>例外処理のログ</h1>";
  document.body.insertBefore(this.p,document.body.firstChild);
}
  return this;
}
STLog.prototype.add = function(e,code) {
if (this.jo) {
  this.p.innerHTML += "<p>"+code+":"+e.message+"</p>";
}
}

//SVGtoVML 本体。SVGDocumentの代わりを担う
//object要素の幅と高さがwとh（単位はpxに統一）。svg要素の幅と高さがswi.valueとshi.value。svg要素にwidth属性が指定されていない場合、swi.value=wである。
function SVGtoVML( /*element*/ obc, /*float*/ w, /*float*/ h, /*STLength*/ swi, /*STLength*/ shi) {
  this.rootElement = obc; this.w = w; this.h = h; this.swi = swi; this.shi = shi;
  return this;
}
SVGtoVML.prototype.read = function stvread(/*element*/ ob) {
  this.rootElement.style.visibility = "hidden";
  this.vi = new STViewSpec(this.rootElement);
  try{
  this.children = []; //子要素
  var sw = this.swi.value,  sh = this.shi.value;
  this.getObject("USE", STUseElement, "use", sw, sh); //use要素を先に処理
  var mat = this.vi.set(sw, sh, ob); //返り値はMatrix型
  this.chset(this.rootElement, mat, sw, sh);
  } catch(n) {stlog.add(n,109);}
}
SVGtoVML.prototype.getObject = function stvgetob( /*string*/ tag, /*object*/ st, /*string*/nodes, /*float*/w, h) {
  try {
  var li = this.rootElement.getElementsByTagName(tag);
  var la = [];
  for (var i=0,lli=li ? li.length : 0;i<lli;++i) {
    la[i] = new st(li[i], w, h);
  }
  this[nodes] = la;
  li = null;
  } catch(e) {stlog.add(e,129);}
}
SVGtoVML.prototype.set = function stvset(ob) {
  var w = this.w, h = this.h, c = this.children;
  var sw = this.swi.value, sh = this.shi.value;
  this.setObject(this.use,sw,sh);
  this.setObject(c,sw,sh);
  try {
  var backr = document.createElement("v:rect"); //背景の作成
  backr.style.position = "absolute";
  backr.style.width = w+ "px";
  backr.style.height = h+ "px";
  backr.style.zIndex = -1;
  backr.stroked = "false";
  backr.filled = "false";
  this.rootElement.appendChild(backr);
  var trstyle = this.rootElement.style;
  var tpstyle = ob.style;
  trstyle.visibility = "visible";
  //以下、画像を切り取り
  trstyle.overflow = "hidden";
  var backrs = backr.currentStyle;
  var viewWidth = w > sw ? sw : w, viewHeight = h > sh ? sh : h; //ウィンドウ枠の長さを決定する
  var bfl = parseFloat(backrs.left), bft = parseFloat(backrs.top);
  var bl = -this.vi._tx, bt = -this.vi._ty;
  if (bfl !== 0 && !isNaN(bfl)) { //内部の図形にずれが生じたとき(isNaNはIE8でautoがデフォルト値のため）
    bl = bfl;
    tpstyle.left = -bl+ "px";
  }
  if (bft !== 0 && !isNaN(bfl)) {
    bt = bft;
    tpstyle.top = -bt+ "px";
  }
  var backright = bl + viewWidth + 1;
  var backdown = bt + viewHeight + 1;
  trstyle.clip = "rect(" +bt+ "px " +backright+ "px " +backdown+ "px " +bl+ "px)";
  //以下、テキストの位置を修正
  var text = this.rootElement.getElementsByTagName("div");
  for (var i=0,textli=text.length;i<textli;++i) {
    var texti = text[i];
    if (texti.firstChild.nodeName !== "shape") { //radialGradient用のdiv要素でないならば
      var tis = texti.style;
      tis.left = parseFloat(tis.left) + bl + "px";
      tis.top = parseFloat(tis.top) + bt + "px";
      //以下はdiv要素がa要素のスタイルを継承しないので必要
      var tp = texti.parentNode;
      while (tp.nodeName === "group") { //group要素である限り、さかのぼる
        tp = tp.parentNode;
      }
      if (tp.nodeName === "A") { //先祖要素がa要素ならば
        tis.cursor = "hand";
      }
    }
  }
  } catch(e) {stlog.add(e,138);}
}
SVGtoVML.prototype.setObject = function stvsetob( /*SVGElement*/ arr, /*float*/ sw, /*float*/ sh) {
  try {
  for (var i=0,arri=arr.length;i<arri;++i) {
      arr[i].set(sw,sh);
  }
  } catch(e) {stlog.add(e,170);}
}

//chset childNodesで要素を作成していく
SVGtoVML.prototype.chset = function _s_chset( /*element*/ ele, /*Matrix*/ matrix, /*float*/w, /*float*/h){
  var nods = ele.childNodes, s = null;
  var name = "group|shape|defs|STOP|fill|stroke|DIV|SPAN|A|image|rect|USE", gname = "DIV|group"; //要素名に合致させる文字列
  var cmatrix = matrix; //子要素に継がせるCTM
  var te = nods[0];
  if (te !== void 0) {
  do {
  try{
    if (name.indexOf(te.nodeName) === -1) { //タグ名が一致しないのであれば
      var ns = te.nextSibling; //次のノードをnsに収納
      var er = ele.removeChild(te);
      er = null;
      te = ns;
    } else {
      if (te.nodeType === 1) { //要素ならば
        if (te.nodeName === "shape") {
          switch (te.getAttribute("tag")) {
            case "path":
              s = new STPath(te, matrix);
            break;
            case "rect":
              s = new STRectElement(te, matrix, w, h);
            break;
            case "circle":
              s = new STCircle(te, matrix, w, h);
            break;
            case "ellipse":
              s = new STEllipse(te, matrix, w, h);
            break;
            case "polyline":
              s = new STPolyline(te, matrix);
            break;
            case "polygon":
              s = new STPolygon(te, matrix);
            break;
            case "line":
              s = new STLine(te, matrix, w, h);
            break;
          }
        } else if (te.nodeName === "DIV") {
          s = new STText(te, matrix, w, h);
        } else if (te.nodeName === "group") {
          s = new STGroupElement(te, matrix, w, h);
        } else if (te.nodeName === "A") {
          s = new STAElement(te, matrix);
          cmatrix = s.transformable;
        } else if (te.nodeName === "image") {
          s = new STImage(te, matrix, w, h);
        }
        if (s) {
          this.children[this.children.length] = s;
          var s = null; //var宣言によって、再設定
        }
        if (gname.indexOf(te.nodeName) === -1) {
          this.chset(te, cmatrix, w, h);
        }
      }
      te = te.nextSibling;
    }
  } catch(e){stlog.add(e,3002);}
  } while (te);
  }
  nods = name = gname = matrix = cmatrix = w = h = null;
}

//object要素とembed要素の取得を総括して行う
function Objectembeds(){
  this.obj = document.getElementsByTagName("object") || {length:0};
  this.emd = document.getElementsByTagName("embed") || {length:0};
  this.onumber = this.enumber = 0;
  return this;
}
Objectembeds.prototype.next = function(){
  try{
  if (this.onumber < this.obj.length) { //object要素の読み込みをまず行う
    var n = this.onumber;
    this.onumber++;
    try {
      getURL(this.obj[n].getAttribute("data"),ca,this.obj,n+1); //data属性をロード
    } catch(e) {stlog.add(e,177);this.next();}
  } else if (this.enumber < this.emd.length) { //object要素が終われば、次にembed要素の読み込み
    var n = this.onumber+this.enumber;
    this.enumber++;
      try {
        getURL(this.emd[n].src,ca,this.emd,n+1);
      } catch(e) {stlog.add(e,185);this.next();}
  } else { //全要素の読み込みが終われば
  }
  } catch(e) {stlog.add(e,293);this.onumber++;this.next();}
}
//embed要素をobject要素に変える(Firefoxのみ)
Objectembeds.prototype.ffnext = function(){
  try{
    for (var i=0,teli=this.emd.length;i<teli;++i) {
      var s = document.createElement("object"), tei = this.emd[i];
      s.setAttribute("data", tei.getAttribute("src"));
      s.setAttribute("type", "image/svg+xml");
      s.setAttribute("width", tei.getAttribute("width")); s.setAttribute("height", tei.getAttribute("height"));
      var tep = tei.parentNode;
      tep.insertBefore(s,tei);
      tep.removeChild(tei);
	  teli--;
    }
  } catch(e) {stlog.add(e,294);}
}

//g要素の処理
function STGroupElement( /*element*/ g, /*Matrix*/ matrix, /*float*/w, h) {
  try{
  this.tar = g;
  this.transformable = NAIBU.transformToCTM(g,matrix); //g要素のtransform属性を前もって処理
  //以下、ツリーとして処理
  this.children = [];
  this.chset(g,this.transformable, w, h);
  w = h = null;
  } catch(e){stlog.add(e,3144);}
  return this;
}
STGroupElement.prototype.set = function (sw,sh) {
  try{
  stvsetob(this.children,sw,sh);
  this.children = this.transformable = null;
  } catch(e){stlog.addd(e,3145)}
};
STGroupElement.prototype.chset = SVGtoVML.prototype.chset;

//a要素の処理
function STAElement( /*element*/ a, /*Matrix*/ matrix) {
  this.xlink = new NAIBU.XLink(a);
  this.target = a.getAttribute("target");
  this.transformable = NAIBU.transformToCTM(a,matrix);
  return this;
}
STAElement.prototype.set = function aset() {
  try {
    var t = this.target;
    var st = "replace";
    if (t === "_blank") {
      st = "new";
    }
    this.xlink.tar.setAttribute("xlink:show",st);
    this.xlink.set();
    var txts = this.xlink.tar.style;
    txts.cursor = "hand";
    txts.left = "0px";
    txts.top = "0px";
    txts.textDecoration = "none";
  }  catch(e) {stlog.add(e,204);}
}

//text要素の処理
function STText( /*element*/ te, /*Matrix*/ matrix, /*float*/w, h) {
  this.tar = te;
  this.x = new STLength((te.getAttribute("x") || 0), w);
  this.y = new STLength((te.getAttribute("y") || 0), h);
  this.dx = te.getAttribute("dx") || null;
  this.dy = te.getAttribute("dy") || null;
  this.paint = new NAIBU.FontStyle(te);
  this.transformable = NAIBU.transformToCTM(te,matrix);
  try { //子要素のtspan要素を処理
    var li = this.tar.getElementsByTagName("SPAN");
    var l = [];
    for (var i=0,lli=li.length;i<lli;++i) {
      l[i] = new STTSpanElement(li[i],this.dx,this.dy,this.transformable, w, h);
    }
    this.tspan = l;
    li = w = h = null;
  } catch(e) {stlog.add(e,129264);}
  return this;
}
STText.prototype.set = function textset( /*float*/ w, /*float*/ h) {
  try {
  var ttm = this.transformable;
  var p = new Point(this.x.value,this.y.value);
  var ptm = p.matrixTransform(ttm);
  var tts = this.tar.style;
  tts.position = "absolute";
  var ttp = this.tar.parentNode;
  if (ttp.lastChild.nodeName !== "rect") {
    var backr = document.createElement("v:rect");
    var backrs = backr.style; //ずれを修正するためのもの
    backrs.width = "1px";
    backrs.height = "1px";
    backrs.left = "0px";
    backrs.top = "0px";
    backr.stroked = "false";
    backr.filled = "false";
    ttp.appendChild(backr);
  }
  tts.width = "0px";
  tts.height = "0px";
  this.paint.fset(w,h,ttm);
  } catch(e) {stlog.add(e,236);}
  try {
    //以下は、テキストの幅であるtextLengthを算出する
    var arr = this.tspan, textLength = 0, fontSize = this.paint.fontSize, atfontSize = 0, fij = /[fijlt.,:;1]/g; //fontSizeは親要素の文字サイズ。atfontSizeは各span要素のサイズ。
    for (var i=0,s={dx:0,dy:0},arri=arr.length;i<arri;++i) {
      var ari = arr[i];
      ari.paint.fset(w,h,ari.transformable);
      var atps = ari.tar.previousSibling;
      if (atps && atps !== void 0) {
        if (atps.nodeType === 3) { //tspan要素の前がText Nodeならば
          var ad = atps.data;
          var alm = fij.test(ad) ? ad.match(fij).length : 0; //iなどはカーニング調整をする
          textLength += (2 * ad.length - alm) * fontSize / 2;
        } else {
          var ai = atps.innerText;
          var alm = fij.test(ad) ? ai.match(fij).length : 0;
          textLength += (2 * ai.length - alm) * atfontSize / 2;
        }
      }
      atfontSize = ari.paint.fontSize;
      s = ari.set(w,h,s);
    }
    if (arr.length === 0) {  //tspan要素がなければ
      var tti = this.tar.innerText;
      var alm = fij.test(tti) ? tti.match(fij).length : 0;
      textLength = (2 * tti.length - alm) * fontSize / 2;
    }
    //以下はtext-anchorプロパティをサポートする。
    var tancx = 0, tancy = 0;
    if (tts.textAnchor === "middle") {  //中寄せならば
      tancx = tancy = textLength / 4;
    } else if (tts.textAnchor === "end") {
      tancx = tancy = textLength / 2;
    }
    if (this.paint.writingMode.indexOf("tb") === 0) { //縦書きならば、x座標に影響を与えない
      tancx = -fontSize * 0.04; //さらにディセンダの調整を行う
    } else {
      tancy = -fontSize * 0.04;
    }
    tts.left = ptm.x - tancx;
    tts.top = ptm.y - tancy;
    p = ptm = tancx = tancy = fij = w = h = null;
    this.textLength = textLength;
  } catch(e) {stlog.add(e,2831);}
  p = ptm = tancx = tancy = null;
  this.textLength = textLength;
}
//fontset フォントの大きさを幅と高さを使ってpx単位に変換
function fontset( /*float*/ f, /*float*/ w, /*float*/ h, /*Matrix*/ ttm) {
  try {
  var sw = new STLength(f, Math.sqrt((w*w + h*h) / 2));
  var swx = sw.value * Math.sqrt(Math.abs(ttm.determinant()));
  sw = null;
  } catch(e) {stlog.add(e,282);swx=f;}
  return swx;
}

//span要素の処理
function STTSpanElement( /*element*/ ele, /*string*/ dx, /*string*/ dy, /*Matrix*/ matrix, /*float*/w, h) {
  this.tar = ele;
  var x = ele.getAttribute("x"), y = ele.getAttribute("y"), spandx = ele.getAttribute("dx"), spandy = ele.getAttribute("dy");
  this.x = x ? new STLength(x, w) : null;
  this.y = y ? new STLength(y, h) : null;
  this.dx = (dx || spandx) ? new STLength(spandx || dx) : null; //自分の要素と親要素が両方ともdx属性を持たないならば、nullにしてずらさないようにする。
  this.dy = (dy || spandy) ? new STLength(spandy || dy) : null;
  this.paint = new NAIBU.FontStyle(ele);
  this.transformable = NAIBU.transformToCTM(ele, matrix);
  return this;
}
//ddはずれの値を持つオブジェクトをあらわす
STTSpanElement.prototype.set = function(w, h, dd) {
  try {
  var tts = this.tar.style;
  tts.position = "relative";
  tts.left = (this.dx ? this.dx.value : 0) + dd.dx+ "px";
  tts.top = (this.dy ? this.dy.value : 0) + dd.dy+ "px";
  var p, ptm;
  if (this.x && this.y) { //x属性とy属性が指定されていたならば（注：仕様と相違がある可能性?）。
    p = new Point(this.x.value, this.y.value);
    ptm = p.matrixTransform(this.transformable);
    tts.position = "absolute";
    tts.left = ptm.x+ "px";
    tts.top = ptm.y+ "px";
  }
  p = ptm = w = h = null;
  //ずれの値を返す
  return {dx : parseFloat(tts.left), dy : parseFloat(tts.top)}
  } catch(e) {stlog.add(e,304);}
}

//line要素の処理
function STLine( /*element*/ li, /*Matrix*/ matrix, /*float*/w, h) {
  this.tar = li;
  this.x1 = new STLength((li.getAttribute("x1") || 0), w);
  this.y1 = new STLength((li.getAttribute("y1") || 0), h);
  this.x2 = new STLength((li.getAttribute("x2") || 0), w);
  this.y2 = new STLength((li.getAttribute("y2") || 0), h);
  this.paint = new NAIBU.PaintColor(li);
  this.transformable = NAIBU.transformToCTM(li,matrix);
  return this;
}
STLine.prototype.set = function lineset(w,h) {
  try {
    var ttm = this.transformable;
    var list = ["m", this.x1.value, this.y1.value, "l", this.x2.value, this.y2.value];
    var pl = new PList(list);
    var plm = pl.matrixTransform(ttm);
    var dat = plm.list.join(" ");
    var ele = this.tar;
    ele.path = dat;
    ele.coordsize = w + " " + h;
    this.paint.set(w, h, ttm);
    list = pl = plm = dat = this.paint = ttm = this.transformable = w = h = null;
  } catch(e) {stlog.add(e,257);}
}

//path要素の処理
function STPath( /*element*/ ele, /*Matrix*/ matrix) {
  this.tar = ele;
  this.d = ele.getAttribute("d");
  this.paint = new NAIBU.PaintColor(ele);
  this.transformable = NAIBU.transformToCTM(ele,matrix);
  return this;
}
STPath.prototype.set = function ( /*float*/ w, /*float*/ h) {
  var dat = "";
  try {
    var dd = this.d
      .replace(/\s*([A-DF-Z])/gi, '],["$1" ') //convert to JSON array
      .replace(/^\],/, "[")
      .replace(/\s*$/, "]]")
      .replace(/[\s,]{2,}|\s/g, ",")
      .replace(/([\d.])-/g, "$1,-");
    var D = eval('('+dd+')'); //ここまでd属性のパーサ
    var ttm = this.transformable;
    var preCom;
    var x = 0, y = 0;   //現在の点の絶対座標
    var x0 = 0, y0 = 0; //subpath の始点の絶対座標
    var dx = 0, dy = 0;
    var tma = ttm.a, tmb = ttm.b, tmc = ttm.c, tmd = ttm.d, tme = ttm.e, tmf = ttm.f;
    for (var i = 0, Dli = D.length; i < Dli; ++i) {
      var F = D[i];
      var com = F[0].toLowerCase(); //F[0]の値はコマンド文字
      var rel = (com === F[0]);     //相対座標のコマンドならtrue
      if (com === "z") {
        F = ["x"];
        x = x0; y = y0;
      } else if (com === "a") { //ArcTo
        F[0] = "c";
        preCom = com;
        var relx = 0, rely = 0;
        if (rel) {
          relx = x; rely = y;
        }
        var ar = new STArc();
        ar.sset(x, y, F, relx, rely);
        x = F[F.length-2] + relx;
        y = F[F.length-1] + rely;
        var pl = new PList(ar.D);
        var plm = pl.matrixTransform(ttm);
        F = ["c"].concat(plm.list);
        if (F.length === 8) {
          F[7] = "";
        }
      } else {
        var rx = x, ry = y;
        if (rel) {
          rx = ry = 0;
        }
        switch (com) { //ここはif文ではなくて、switch文で処理する必要がある。
          case "h": F = ["l", F[F.length-1], ry];
          break;
          case "v": F = ["l", rx, F[F.length-1]];
          break;
          case "s": F[0] = "c"; if (preCom !== "c") {dx = dy = 0;} F = NAIBU.nst(6, F, rx + dx, ry + dy);
          break;
          case "t": F[0] = "q"; if (preCom !== "q") {dx = dy = 0;} F = NAIBU.nst(4, F, rx + dx, ry + dy);
          break;
          default:  F[0] = com; //"M", "L", "C", "Q" は小文字に変換
        }
        if (rel) {
          F = NAIBU.reltoabs(x, y, F); //絶対座標に変換
        }
        preCom = com = F[0];
        if (com === "c" || com === "q") {
          var Fli = F.length;
          dx = F[Fli-2] - F[Fli-4];
          dy = F[Fli-1] - F[Fli-3];
        }
        if (com === "q") {
          F = NAIBU.qtoc(x, y, F); //二次ベジェは三次ベジェに変換
        }
        if (com === "m") {
          x0 = F[1]; y0 = F[2]; //subpath の始点を記憶
        }
        var Fli = F.length;
        x = F[Fli-2];
        y = F[Fli-1];
        var _x, _y; //この変数は初期化されないために必要
        for (var j = 1; j < Fli; j += 2) { //CTMで座標変換
          _x = parseInt(tma * F[j] + tmc * F[j+1] + tme, 10);
          _y = parseInt(tmb * F[j] + tmd * F[j+1] + tmf, 10);
          F[j]   = _x;
          F[j+1] = _y;
        }
        if (com === "m" && Fli > 3) { //MoveToが複数の座標ならば、2番目以降の座標ペアをLineToとして処理
          F.splice(3, 0, "l");
        }
      }
      dat += F.join(" ");
      F = null;
    }
    D = dd = Fli = null; //解放
  } catch(e) {if(this.d == ""){/*d属性が空*/}else{stlog.add(e,355);}}
  try {
    var ele = this.tar;
    ele.path = dat + " e";
    ele.coordsize = w + " " + h;
    this.paint.set(w, h, ttm);
    dat = this.paint = ttm = this.transformable = this.d = preCom = x = y = x0 = y0 = dx = dy = tma = tmb = tmc = tmd = tme = tmf = w = h = null; //解放
  } catch(e) {stlog.add(e,372);}
};

//QからCに変換
NAIBU.qtoc = function (/*float*/ x, /*float*/ y, /*Array*/ F) {
  F[0] = "c";
  for (var i = 1; i < F.length; i += 6) {
    var x1 = F[i], y1 = F[i+1], x2 = F[i+2], y2 = F[i+3];
    F.splice(i, 2, (x + 2 * x1) / 3, (y + 2 * y1) / 3, (2 * x1 + x2) / 3, (2 * y1 + y2) / 3);
    x = x2; y = y2;
  }
  return F;
}

//前回の座標を反転させる。それを挿入
NAIBU.nst = function ( /*int*/ skip, /*Array*/ F, /*float*/ x1, /*float*/ y1) {
  F.splice(1, 0, x1, y1);
  for (var i = skip+1; i < F.length; i += skip) {
    x1 = 2 * F[i-2] - F[i-4];
    y1 = 2 * F[i-1] - F[i-3];
    F.splice(i, 0, x1, y1);
  }
  return F;
}

//相対座標を絶対座標に変換
NAIBU.reltoabs = function (/*float*/ x, /*float*/ y, /*Array*/ F) {
  var skip = 2;
  if (F[0] === "c") { 
    skip = 6;
  } else if (F[0] === "q") {
    skip = 4;
  }
  for (var i = 1, Fli = F.length; i < Fli; i += 2) {
    F[i] += x; F[i+1] += y;
    if ((i+1) % skip === 0) {
      x = F[i]; y = F[i+1];
    }
  }
  return F;
}

//polygon要素を処理
function STPolygon( /*element*/ ele, /*Matrix*/ matrix) {
  this.tar = ele;
  this.points = ele.attributes["points"].nodeValue;
  this.paint = new NAIBU.PaintColor(ele);
  this.transformable = NAIBU.transformToCTM(ele,matrix);
  return this;
}
STPolygon.prototype.set = function polygonset(w,h) {
  var dat;
  var ttm = this.transformable;
  try {
    var F = this.points.replace(/^\s+|\s+$/g, "").split(/[\s,]+/);
    var pl = new PList(F);
    var plm = pl.matrixTransform(ttm);
    plm.list.splice(2, 0, "l");
    dat = "m" + plm.list.join(" ") + "x e";
  } catch(e) {stlog.add(e,395);}
  try {
    var ele = this.tar;
    ele.path = dat;
    ele.coordsize = w + " " + h;
    this.paint.set(w, h, ttm);
  } catch(e) {stlog.add(e,406);}
}

//polyline要素を処理
function STPolyline( /*element*/ ele, /*Matrix*/ matrix) {
  this.tar = ele;
  this.points = ele.attributes["points"].nodeValue;
  this.paint = new NAIBU.PaintColor(ele);
  this.transformable = NAIBU.transformToCTM(ele,matrix);
  return this;
}
STPolyline.prototype.set = function polylineset(w,h) {
  var dat;
  var ttm = this.transformable;
  try {
    var F = this.points.replace(/^\s+|\s+$/g, "").split(/[\s,]+/);
    var pl = new PList(F);
    var plm = pl.matrixTransform(ttm);
    plm.list.splice(2, 0, "l");
    dat = "m" + plm.list.join(" ") + "e";
  } catch(e) {stlog.add(e,429);}
  try {
    var ele = this.tar;
    ele.path = dat;
    ele.coordsize = w + " " + h;
    this.paint.set(w, h, ttm);
  } catch(e) {stlog.add(e,440);}
}

//circle要素を処理
function STCircle( /*element*/ ele, /*Matrix*/ matrix, /*float*/w, h) {
  this.tar = ele;
  try {
    this.cx = new STLength((ele.getAttribute("cx") || 0), w);
    this.cy = new STLength((ele.getAttribute("cy") || 0), h);
    this.r = new STLength(ele.getAttribute("r"));
    this.paint = new NAIBU.PaintColor(ele);
    this.transformable = NAIBU.transformToCTM(ele,matrix);
    w = h = null;
  } catch(e) {stlog.add(e,450);}
  return this;
}
//ベジェ曲線で円を表現する
STCircle.prototype.set = function ovalset(w,h) {
  var cx = this.cx.value, cy = this.cy.value, rx = ry = this.r.value;
  var top = cy - ry, left = cx - rx, bottom = cy + ry, right = cx + rx;
  try {
  var ttm = this.transformable;
  var rrx = rx * 0.55228, rry = ry * 0.55228;
  var list = ["m", cx,top, "c", cx-rrx,top, left,cy-rry, left,cy, left,cy+rry, cx-rrx,bottom, cx,bottom, cx+rrx,bottom, right,cy+rry, right,cy, right,cy-rry, cx+rrx,top, cx,top, "x e"];
  var pl = new PList(list);
  var plm = pl.matrixTransform(ttm);
  var dat = plm.list.join(" ");
  } catch(e) {stlog.add(e,468);}
  try {
    var ele = this.tar;
    ele.path = dat;
    ele.coordsize = w + " " + h;
    this.paint.set(w, h, ttm);
    dat = list = pl = plm = this.paint = ttm = this.transformable = w = h = null; //解放
  } catch(e) {stlog.add(e,479);}
}

//ellipse要素を処理
function STEllipse( /*element*/ ele, /*Matrix*/ matrix, /*float*/w, h) {
  this.tar = ele;
  try {
    this.cx = new STLength((ele.getAttribute("cx") || 0), w);
    this.cy = new STLength((ele.getAttribute("cy") || 0), h);
    this.rx = new STLength(ele.getAttribute("rx"), w);
    this.ry = new STLength(ele.getAttribute("ry"), h);
    this.paint = new NAIBU.PaintColor(ele);
    this.transformable = NAIBU.transformToCTM(ele,matrix);
    w = h = null;
  } catch(e) {stlog.add(e,490);}
  return this;
}
STEllipse.prototype.set = function elliset(w,h) {
  var cx = this.cx.value, cy = this.cy.value, rx = this.rx.value, ry = this.ry.value;
  var top = cy - ry, left = cx - rx, bottom = cy + ry, right = cx + rx;
  try {
  var ttm = this.transformable;
  var rrx = rx * 0.55228, rry = ry * 0.55228;
  var list = ["m", cx,top, "c", cx-rrx,top, left,cy-rry, left,cy, left,cy+rry, cx-rrx,bottom, cx,bottom, cx+rrx,bottom, right,cy+rry, right,cy, right,cy-rry, cx+rrx,top, cx,top, "x e"];
  var pl = new PList(list);
  var plm = pl.matrixTransform(ttm);
  var dat = plm.list.join(" ");
  } catch(e) {stlog.add(e,508);}
  try {
    var ele = this.tar;
    ele.path = dat;
    ele.coordsize = w + " " + h;
    this.paint.set(w, h, ttm);
    dat = list = pl = plm = this.paint = ttm = this.transformable = w = h = null; //解放
  } catch(e) {stlog.add(e,519);}
}

//rect要素を処理
function STRectElement( /*element*/ rect, /*Matrix*/ matrix, /*float*/ w, h) {
  this.tar = rect;
  try {
    this.x = new STLength((rect.getAttribute("x") || 0), w);
    this.y = new STLength((rect.getAttribute("y") || 0), h);
    this.width = new STLength(rect.getAttribute("svgwidth"), w);
    this.height = new STLength(rect.getAttribute("svgheight"), h);
    var rx = rect.getAttribute("rx"), ry = rect.getAttribute("ry");
    if (rx || ry) {
      this.rx = new STLength((rx || ry), w);
      this.ry = new STLength((ry || rx), h);
      if (this.rx.value > this.width.value / 2) { //rx属性が幅より大きければ、幅の半分を属性に設定
        this.rx.value = this.width.value / 2;
      }
      if (this.ry.value > this.height.value / 2) {
        this.ry.value = this.height.value / 2;
      }
    }
    this.paint = new NAIBU.PaintColor(rect);
    this.transformable = NAIBU.transformToCTM(rect,matrix);
    w = h = rx = ry = null;
  } catch(ee) {stlog.add(ee,545);}
  return this;
}
STRectElement.prototype.set = function rectset(w,h) {
  try {
    var x = this.x.value, y = this.y.value, xw = x + this.width.value, yh = y + this.height.value;
    var list;
    if (this.rx) {
      var rx = this.rx.value, ry = this.ry.value;
      var rrx = rx * 0.55228, rry = ry * 0.55228;
      var a = xw - rx, b = x + rx, c = y + ry, d = yh - ry;
      list = ["m",b,y, "l",a,y, "c",a+rrx,y,xw,c-rry,xw,c, "l",xw,d, "c",xw,d+rry,a+rrx,yh,a,yh, "l",b,yh, "c",b-rrx,yh,x,d+rry,x,d, "l",x,c, "c",x,c-rry,b-rrx,y,b,y];
    } else {
      list = ["m",x,y, "l",x,yh, xw,yh, xw,y, "x e"];
    }
    var ttm = this.transformable;
    var pl = new PList(list);
    var plm = pl.matrixTransform(ttm);
    var dat = plm.list.join(" ");
  } catch(e) {stlog.add(e,564);}
  try {
    var ele = this.tar;
    ele.path = dat;
    ele.coordsize = w + " " + h;
    this.paint.set(w, h, ttm);
    dat = list = pl = plm = this.paint = ttm = this.transformable = w = h = null; //解放
  } catch(ee) {stlog.add(ee,576);}
}

//image要素の処理
function STImage( /*element*/ ele, /*Matrix*/ matrix, /*float*/w, h){
  this.tar = ele;
  this.x = new STLength((ele.getAttribute("x") || 0), w);
  this.y = new STLength((ele.getAttribute("y") || 0), h);
  this.width = new STLength(ele.getAttribute("svgwidth"), w);
  this.height = new STLength(ele.getAttribute("svgheight"), h);
  ele.setAttribute("xlink:show", "embed");
  this.xlink = new NAIBU.XLink(ele);
  this.paint = new NAIBU.PaintColor(ele);
  this.transformable = NAIBU.transformToCTM(ele,matrix);
  w = h = null
  return this;
}
STImage.prototype.set = function imagesets(w,h){
  try {
    var ttm = this.transformable;
    var ts = this.tar.style;
    ts.position = "absolute";
    var pt = new Point(this.x.value, this.y.value);
    var ptt = pt.matrixTransform(ttm);
    ts.left = ptt.x+ "px";
    ts.top =  ptt.y+ "px";
    ts.width = this.width.value * ttm.a+ "px";
    ts.height = this.height.value * ttm.d+ "px";
    if (ttm.b !== 0 || ttm.c !== 0 || this.paint.fillopacity != 1) {//フィルター　プロパティを使うと、PNGの透過性がなくなるので注意
      ts.filter = "progid:DXImageTransform.Microsoft.Matrix progid:DXImageTransform.Microsoft.Alpha";
      var ttfi = this.tar.filters.item('DXImageTransform.Microsoft.Matrix');
      ttfi.M11 = 1;
      ttfi.M12 = ttm.b;
      ttfi.M21 = ttm.c;
      ttfi.M22 = 1;
      ttfi.sizingMethod = "auto expand";
      var ttfia = this.tar.filters.item('DXImageTransform.Microsoft.Alpha');
      ttfia.Style = 0;
      ttfia.Opacity = parseFloat(this.paint.fillopacity)*100;
    }
    this.xlink.set();
    dat = pt = this.xlink = this.paint = ttm = this.transformable = w = h = null; //解放
  } catch(e) {stlog.set(e,21896);}
}

/*use要素の処理*/
function STUseElement( /*element*/ ele,  /*float*/w, h){
  this.tar = ele;
  var tns = ele.nextSibling;
  tns.setAttribute("xlink:show", "embed")
  this.x = new STLength((tns.getAttribute("x") || 0), w);
  this.y = new STLength((tns.getAttribute("y") || 0), h);
  this.width = new STLength(tns.getAttribute("svgwidth"), w);
  this.height = new STLength(tns.getAttribute("svgheight"), h);
  this.xlink = new NAIBU.XLink(tns);
  var ts = tns.getAttribute("transform") || "";
  this.xlink.set();
  tns.setAttribute("transform", ts+ " translate(" +this.x.value+ "," +this.y.value+ ")");
  tns.firstChild.setAttribute("id","");
  tns.coordorgin = "0  0";
  this.paint = new NAIBU.PaintColor(this.xlink.resource);
  this.paint.tar = tns;
  w = h = null;
  return this;
}
STUseElement.prototype.set = function(){
  try {
    this.paint.setStyle();
    this.paint = this.xlink = null;
  } catch(e) {stlog.add(e,85436);}
}

//色のキーワード
//PaintColor 色、線などをすべてコントロール
NAIBU.PaintColor = function( /*element*/ ele) {
if (ele) {
  this.tar = ele;
  var defaults = this.defaults;
  var parent = this.getParent(ele); //親要素のPaintColorオブジェクト
  if (parent) {
    for (var name in defaults) {
      if (defaults.hasOwnProperty(name)) {
        if (name === "opacity") {
          this[name] = (this.getAttribute(name) || 1) * parent[name]; //親要素のopacityを掛け合わせる
        } else {
          this[name] = this.getAttribute(name) || parent[name]; //指定がなければ親要素の値を継承
          if (this[name] === "inherit") { //値がinheritなら親のを継承
            this[name] = parent[name];
          } else if (this[name] === "currentColor") {
            this[name] = this.getAttribute("color") || parent.getAttribute("color");
          }
        }
      }
      name = null;
    }
  } else {
    for (var name in defaults) {
      this[name] = this.getAttribute(name) || defaults[name]; //指定がなければデフォルト値に設定
      name = null;
    }
  }
}
  return this;
};
//デフォルト値のリスト
NAIBU.PaintColor.prototype.defaults = {
  fill: "black",
  fillopacity: 1,
  stroke: "none",
  strokewidth: "1",
  strokelinecap: "butt",
  strokelinejoin: "miter",
  strokemiterlimit: "4",
  strokedasharray: "none",
  strokeopacity: 1,
  opacity: 1,
  cursor: "default"
};
//キャッシュ用
NAIBU.PaintColor.prototype.cache = {};
//親コンテナ要素のPaintColorオブジェクトを返す
NAIBU.PaintColor.prototype.getParent = function( /*element*/ ele) {
  var parent = ele.parentNode;
  if (parent.tagName !== "group" && parent.tagName !== "A") {
    return null;
  } else {
    var cache = this.cache;
    var id = parent.uniqueID;
    if (!cache[id]) {
      cache[id] = new NAIBU.PaintColor(parent);
    }
    return cache[id];
  }
};
NAIBU.PaintColor.prototype.getAttribute = function ( /*string*/ name) {
  try {
    var element = this.tar;
    var style = element.style[name];
    if (style) {
      return style;
    }
    var attribute = element.attributes[name];
    var s = attribute ? attribute.nodeValue : null;
    return s;
  } catch(e) {stlog.add(e,659); return null;}
};
//内部プロパティを、styleに設定する
NAIBU.PaintColor.prototype.setStyle = function() {
  try {
    var tst = this.tar
    for (var i in this) {
      if ((typeof this[i]) === "string") { //string型以外は除く
        tst.style[i] = this[i];
      }
    }
  } catch(e) {stlog.add(e,899); return "";}
};
NAIBU.PaintColor.prototype._urlreg = /url\(#([^)]+)/;
NAIBU.PaintColor.prototype.set = function (/*float*/ w, /*float*/ h, /*Matrix*/ matrix) {
  var el = this.tar;
  if (this.fill === "none") {
    el.filled = "false";
  } else {
    var fillElement = document.createElement("v:fill");
    var isRadial = false;
    try {
    if (this._urlreg.test(this.fill)) { //fill属性の値がurl(#id)ならば、idを設定したグラデーション関連要素を呼び出す
      this.w = w; this.h = h; //radialGradientで必要
      isRadial = this.gradient(fillElement, RegExp.$1, matrix);
    } else {
      fillElement.setAttribute("color", this.color(this.fill));
      var fillOpacity = this.fillopacity * this.opacity; //opacityを掛け合わせる
      if (fillOpacity < 1) {
        fillElement.setAttribute("opacity", fillOpacity);
      }
    }
    } catch(e) {stlog.add(e,682); fillElement.on = "true";
    fillElement.color = "black";}
    if (!isRadial) {
      el.appendChild(fillElement);
    }
    isRadial = fillOpacity = null;
  }
  if (this.stroke === "none") {
    el.stroked = "false";
  } else {
    var strokeElement = document.createElement("v:stroke");
    try {
    var sw = new STLength(this.strokewidth, Math.sqrt((w*w + h*h) / 2));
    var swx = sw.value * Math.sqrt(Math.abs(matrix.determinant()));
    strokeElement.setAttribute("weight", swx + "px");
    if (this.stroke.match(/url\(#([^)]+)/)) {
      this.gradient(strokeElement, RegExp.$1);
    } else {
      strokeElement.setAttribute("color", this.color(this.stroke));
      var strokeOpacity = this.strokeopacity * this.opacity; //opacityを掛け合わせる
      if (swx < 1) {
        strokeOpacity *= swx; //太さが1px未満なら色を薄くする
      }
      if (strokeOpacity < 1) {
        strokeElement.setAttribute("opacity", strokeOpacity);
      }
      strokeOpacity = null;
    }
    strokeElement.setAttribute("miterlimit", this.strokemiterlimit);
    strokeElement.setAttribute("joinstyle", this.strokelinejoin);
    if (this.strokelinecap === "butt") {
      strokeElement.setAttribute("endcap", "flat");
    } else {
      strokeElement.setAttribute("endcap", this.strokelinecap);
    }
    var tsd = this.strokedasharray;
    if (tsd !== "none") {
      if (tsd.indexOf(",") > 0) { //コンマ区切りの文字列の場合
        var strs = tsd.split(",");
        for (var i = 0, sli = strs.length; i < sli; ++i) {
          strs[i] = Math.ceil(parseFloat(strs[i]) / parseFloat(this.strokewidth)); //精密ではないので注意
        }
        this.strokedasharray = strs.join(" ");
        if (strs.length % 2 == 1) {
          this.strokedasharray += " " + this.strokedasharray;
        }
      }
      strokeElement.setAttribute("dashstyle", this.strokedasharray);
      tsd = strs = null;
    }
    } catch(e) {stlog.add(e,720); strokeElement.on =  "false";}
    el.appendChild(strokeElement);
    sw = tsd = null;
  }
  if (this.cursor !== "default") {
    this.tar.style.cursor = this.cursor;
  }
  w = h = null;
};
//色キーワード
NAIBU.PaintColor.prototype.keywords = {
  aliceblue: "#F0F8FF",
  antiquewhite: "#FAEBD7",
  aquamarine: "#7FFFD4",
  azure: "#F0FFFF",
  beige: "#F5F5DC",
  bisque: "#FFE4C4",
  blanchedalmond: "#FFEBCD",
  blueviolet: "#8A2BE2",
  brown: "#A52A2A",
  burlywood: "#DEB887",
  cadetblue: "#5F9EA0",
  chartreuse: "#7FFF00",
  chocolate: "#D2691E",
  coral: "#FF7F50",
  cornflowerblue: "#6495ED",
  cornsilk: "#FFF8DC",
  crimson: "#DC143C",
  cyan: "#00FFFF",
  darkblue: "#00008B",
  darkcyan: "#008B8B",
  darkgoldenrod: "#B8860B",
  darkgray: "#A9A9A9",
  darkgreen: "#006400",
  darkgrey: "#A9A9A9",
  darkkhaki: "#BDB76B",
  darkmagenta: "#8B008B",
  darkolivegreen: "#556B2F",
  darkorange: "#FF8C00",
  darkorchid: "#9932CC",
  darkred: "#8B0000",
  darksalmon: "#E9967A",
  darkseagreen: "#8FBC8F",
  darkslateblue: "#483D8B",
  darkslategray: "#2F4F4F",
  darkslategrey: "#2F4F4F",
  darkturquoise: "#00CED1",
  darkviolet: "#9400D3",
  deeppink: "#FF1493",
  deepskyblue: "#00BFFF",
  dimgray: "#696969",
  dimgrey: "#696969",
  dodgerblue: "#1E90FF",
  firebrick: "#B22222",
  floralwhite: "#FFFAF0",
  forestgreen: "#228B22",
  gainsboro: "#DCDCDC",
  ghostwhite: "#F8F8FF",
  gold: "#FFD700",
  goldenrod: "#DAA520",
  grey: "#808080",
  greenyellow: "#ADFF2F",
  honeydew: "#F0FFF0",
  hotpink: "#FF69B4",
  indianred: "#CD5C5C",
  indigo: "#4B0082",
  ivory: "#FFFFF0",
  khaki: "#F0E68C",
  lavender: "#E6E6FA",
  lavenderblush: "#FFF0F5",
  lawngreen: "#7CFC00",
  lemonchiffon: "#FFFACD",
  lightblue: "#ADD8E6",
  lightcoral: "#F08080",
  lightcyan: "#E0FFFF",
  lightgoldenrodyellow: "#FAFAD2",
  lightgray: "#D3D3D3",
  lightgreen: "#90EE90",
  lightgrey: "#D3D3D3",
  lightpink: "#FFB6C1",
  lightsalmon: "#FFA07A",
  lightseagreen: "#20B2AA",
  lightskyblue: "#87CEFA",
  lightslategray: "#778899",
  lightslategrey: "#778899",
  lightsteelblue: "#B0C4DE",
  lightyellow: "#FFFFE0",
  limegreen: "#32CD32",
  linen: "#FAF0E6",
  magenta: "#FF00FF",
  mediumaquamarine: "#66CDAA",
  mediumblue: "#0000CD",
  mediumorchid: "#BA55D3",
  mediumpurple: "#9370DB",
  mediumseagreen: "#3CB371",
  mediumslateblue: "#7B68EE",
  mediumspringgreen: "#00FA9A",
  mediumturquoise: "#48D1CC",
  mediumvioletred: "#C71585",
  midnightblue: "#191970",
  mintcream: "#F5FFFA",
  mistyrose: "#FFE4E1",
  moccasin: "#FFE4B5",
  navajowhite: "#FFDEAD",
  oldlace: "#FDF5E6",
  olivedrab: "#6B8E23",
  orange: "#FFA500",
  orangered: "#FF4500",
  orchid: "#DA70D6",
  palegoldenrod: "#EEE8AA",
  palegreen: "#98FB98",
  paleturquoise: "#AFEEEE",
  palevioletred: "#DB7093",
  papayawhip: "#FFEFD5",
  peachpuff: "#FFDAB9",
  peru: "#CD853F",
  pink: "#FFC0CB",
  plum: "#DDA0DD",
  powderblue: "#B0E0E6",
  rosybrown: "#BC8F8F",
  royalblue: "#4169E1",
  saddlebrown: "#8B4513",
  salmon: "#FA8072",
  sandybrown: "#F4A460",
  seagreen: "#2E8B57",
  seashell: "#FFF5EE",
  sienna: "#A0522D",
  skyblue: "#87CEEB",
  slateblue: "#6A5ACD",
  slategray: "#708090",
  slategrey: "#708090",
  snow: "#FFFAFA",
  springgreen: "#00FF7F",
  steelblue: "#4682B4",
  tan: "#D2B48C",
  thistle: "#D8BFD8",
  tomato: "#FF6347",
  turquoise: "#40E0D0",
  violet: "#EE82EE",
  wheat: "#F5DEB3",
  whitesmoke: "#F5F5F5",
  yellowgreen: "#9ACD32"
};
//<color>をVML用に変換
NAIBU.PaintColor.prototype.color = function( /*string*/ color) {
  if (this.keywords[color]) {
    return this.keywords[color];
  }
  if (color.indexOf("%", 5) > 0) { // %を含むrgb形式の場合
    return color.replace(/[\d.]+%/g, function(s) {
      return Math.round(2.55 * parseFloat(s));
    });
  }
  return color;
};
//linearGradient、radialGradient要素を処理
NAIBU.PaintColor.prototype.gradient = function ( /*element*/ ele, /*string*/ id, /*Matrix*/ matrix) {
  var grad = document.getElementById(id);
  if (grad) {
  var grad2 = grad;
  while (grad2 && !grad2.hasChildNodes()) { //stopを子要素に持つgradient要素を探す
    grad2.getAttribute("xlink:href").match(/#(.+)/);
    grad2 = document.getElementById(RegExp.$1);
  }
  var stops = grad2.getElementsByTagName("stop");
  if (!stops) {
    grad = grad2 = stops = null;
    return false;
  }
  var length = stops.length;
  var color = [], colors = [], opacity = [];
  for (var i = 0; i < length; ++i) {
    var stop = stops[i];
    color[i] = this.color(stop.style.stopcolor || stop.getAttribute("stopcolor")) || "black";
    colors[i] = stop.getAttribute("offset") + " " + color[i];
    opacity[i] = (stop.style.stopopacity || stop.getAttribute("stopopacity") || 1) * this.fillopacity * this.opacity;
  }
  ele.setAttribute("method", "none");
  ele.setAttribute("color",  color[0]);
  ele.setAttribute("color2", color[length-1]);
  ele.setAttribute("colors", colors.join(","));
  // When colors attribute is used, the meanings of opacity and o:opacity2 are reversed.
  ele.setAttribute("opacity", opacity[length-1]);
  ele.setAttribute("o:opacity2", opacity[0]);
  var type = grad.getAttribute("type");
  if (type === "gradient") {
  try {
    var angle;
    var x1 = parseFloat((grad.getAttribute("x1") || "0").replace(/%/, ""));
    var y1 = parseFloat((grad.getAttribute("y1") || "0").replace(/%/, ""));
    var x2 = parseFloat((grad.getAttribute("x2") || "100").replace(/%/, ""));
    var y2 = parseFloat((grad.getAttribute("y2") || "0").replace(/%/, ""));
    angle = 270 - Math.atan2(y2-y1, x2-x1) * 180 / Math.PI;
    if (angle >= 360) {
      angle -= 360;
    }
  } catch(e) {stlog.add(e,749); angle = 270;}
    ele.setAttribute("type", "gradient");
    ele.setAttribute("angle", angle + "");
    x1 = y1 = x2 = y2 = angle = null;
  } else if (type === "gradientRadial") {
  try{
    ele.setAttribute("type", "gradientTitle");
    ele.setAttribute("focus", "100%");
    ele.setAttribute("focusposition", "0.5 0.5");
    if (this.tar.getAttribute("tag") === "rect") {
    var cx = parseFloat((grad.getAttribute("cx") || "0.5").replace(/%/, ""));
    var cy = parseFloat((grad.getAttribute("cy") || "0.5").replace(/%/, ""));
    var r = rx = ry = parseFloat((grad.getAttribute("r") || "0.5").replace(/%/, ""));
    var el = this.w, et = this.h, er = 0, eb = 0;
    var data = this.tar.getAttribute("path")+"";
    var units = grad.getAttribute("gradientUnits");
    if (!units || units === "objectBoundingBox") {
      //%の場合は小数点に変換(10% -> 0.1)
      cx = cx > 1 ? cx/100 : cx; cy = cy > 1 ? cy/100 : cy; r = r > 1 ? r/100 : r;
      //要素の境界領域を求める（四隅の座標を求める）
      var degis = data.match(/[0-9\-]+/g);
      for (var i=0,degisli=degis.length;i<degisli;i+=2) {
        var nx = parseInt(degis[i]), ny = parseInt(degis[i+1]);
        el = el > nx ? nx : el;
        et = et > ny ? ny : et;
        er = er > nx ? er : nx;
        eb = eb > ny ? eb : ny; nx = ny = null;
      }
      degis = null;
      cx = cx*(er - el) + el; cy = cy*(eb - et) + et; rx = r*(er - el); ry = r*(eb - et);
    }
    var gt = grad.getAttribute("gradientTransform");
    if (gt) {
      grad.setAttribute("transform",gt);
      matrix = NAIBU.transformToCTM(grad, matrix);
    }
    el = cx - rx; et = cy - ry; er = cx + rx; eb = cy + ry;
    var rrx = rx * 0.55228, rry = ry * 0.55228;
    var list = ["m", cx,et, "c", cx-rrx,et, el,cy-rry, el,cy, el,cy+rry, cx-rrx,eb, cx,eb, cx+rrx,eb, er,cy+rry, er,cy, er,cy-rry, cx+rrx,et, cx,et, "x e"];
    var pl = new PList(list);
    var plm = pl.matrixTransform(matrix);
    var ellipse = plm.list.join(" ");
    var outline = document.getElementById("_NAIBU_outline");
    var background = document.createElement("div");
    background.style.position = "absolute";
    background.style.textAlign = "left"; background.style.top = "0px"; background.style.left = "0px"; background.style.width = this.w+ "px"; background.style.height = this.h+ "px";
    outline.appendChild(background);
    background.style.filter = "progid:DXImageTransform.Microsoft.Compositor";
    background.filters.item('DXImageTransform.Microsoft.Compositor').Function = 23;
    var circle = '<v:shape style="position:relative; antialias:false; top:0px; left:0px;" coordsize="' +this.w+ ' ' +this.h+ '" path="' +ellipse+ '" stroked="f">' +ele.outerHTML+ '</v:shape>';
    background.innerHTML = '<v:shape style="position:relative; top:0px; left:0px;" coordsize="' +this.w+ ' ' +this.h+ '" path="' +data+ '" stroked="f" fillcolor="' +color[color.length-1]+ '" ></v:shape>';
    background.filters[0].apply();
    background.innerHTML = circle;
    background.filters[0].play();
    this.tar.parentNode.insertBefore(background, this.tar);
    this.tar.filled = "false";
    ellipse = circle = data = list = pl = plm = gt = cx = cy = r = null;
    } else {
      return false;
    }
    return true;
    } catch(e) {stlog.add(e,1175);}
  }
  } else {
    return false;
  }
  stops = type = lengh = color = colors = opacity = null;
  return false;
};

//font属性、関連プロパティを処理する
//PaintColorを継承
NAIBU.FontStyle = function( /*element*/ ele) {
  var td = this.defaults;
  td["font-size"] = "12";
  td["font-family"] = "sans-serif";
  td["font-style"] = "normal";
  td["font-weight"] = "400";
  td["text-transform"] = "none";
  td["text-decoration"] = "none";
  td["writing-mode"] = "lr-tb";
  td["text-anchor"] = "start";
  NAIBU.PaintColor.apply(this,arguments);
  return this;
}
NAIBU.FontStyle.prototype = new NAIBU.PaintColor(false);
//キャッシュ用
NAIBU.FontStyle.prototype.cache = {};
//親コンテナ要素のPaintColorオブジェクトを返す
NAIBU.FontStyle.prototype.getParent = function( /*element*/ ele) {
  try{
  var parent = ele.parentNode;
  if (parent.tagName !== "group" && parent.tagName !== "A" && parent.tagName !== "DIV") {
    return null;
  }
  var cache = this.cache;
  var id = parent.uniqueID;
  if (!cache[id]) {
    cache[id] = new NAIBU.FontStyle(parent);
  }
  } catch(e){stlog.add(e,1179);}
  return cache[id];
}

//内部プロパティを、styleに設定する
NAIBU.FontStyle.prototype.setStyle = function() {
  try {
    var tst = this.tar
    for (var i in this) {
      var ti = this[i];
      if ((typeof ti) === "string") { //string型以外は除く
        var sname = i.replace(/\-([a-z])/, "-").replace(/\-/,RegExp.$1.toUpperCase());
        if (ti === "lr") {
          ti = "lr-tb";
        } else if (ti === "tb") {
          ti = "tb-rl";
        }
        tst.style[sname] = ti;
      }
    }
  } catch(e) {stlog.add(e,1396); return "";}
}
NAIBU.FontStyle.prototype.fset = function( /*float*/ w, /*float*/ h, /*Matrix*/ matrix) {
  try{
  this.setStyle();
  var tts = this.tar.style;
  tts.whiteSpace = "nowrap";
  tts.color = this.fill === "none" ? "transparent"  :  this.fill;
  this.fontSize = fontset(this["font-size"],w,h,matrix);
  tts.fontSize = this.fontSize+ "px";
  if (this.cursor !== "default") {
    tts.cursor = this.cursor;
  }
  this.writingMode = tts.writingMode;
  tts.marginTop = (this.writingMode === "tb-rl") ? "0px" : -parseFloat(tts.fontSize)+ "px";
  tts.textIndent = "0px";
 } catch(e){stlog.add(e,1185);}
}

//NAIBU.transformToCTM transform属性を処理。Matrix型に変換
//あらかじめ正規表現オブジェクトを生成しておく
NAIBU.comaR = /[A-Za-z]+(?=\s*\()/g;
NAIBU.listR = /\([^\)]+\)/g;
NAIBU.degR = /[\-\d\.e]+/g;
NAIBU.transformToCTM = function ( /*element*/ ele, /*Matrix*/ matrix) {
  try {
  var tft = ele.getAttribute("transform");
  if (tft) {
    var coma = tft.match(NAIBU.comaR); //コマンド文字にマッチ translate
    var list = tft.match(NAIBU.listR); //カッコ内のリストにマッチ (10 20 30...)
    var a,b,c,d,e,f,lis,deg,rad,degli,matri;
    for (var j=0,cli=coma.length;j<cli;j++) {
      lis = list[j], com = coma[j];
      deg = lis.match(NAIBU.degR);
      degli = deg.length;
      if (degli === 6) {
        a = parseFloat(deg[0]); b = parseFloat(deg[1]); c = parseFloat(deg[2]); d = parseFloat(deg[3]); e = parseFloat(deg[4]); f = parseFloat(deg[5]);
      } else {
        rad = parseFloat(deg[0]) / 180 * Math.PI;
        if (degli === 3) {
          var cx = parseFloat(deg[1]), cy = parseFloat(deg[2]);
          a = Math.cos(rad); b = Math.sin(rad); c = -b; d = a; e = (1-a)*cx-c*cy; f = -b*cx+(1-d)*cy;
        } else if (degli <= 2) {
          switch (com) {
          case "translate":
            a = 1; b = 0; c = 0; d = 1; e = parseFloat(deg[0]); f = parseFloat(deg[1] || 0);
          break;
          case "scale":
            a = parseFloat(deg[0]); b = 0; c = 0; d = parseFloat(deg[1] || deg[0]); e = 0; f = 0;
          break;
          case "rotate":
            a = Math.cos(rad); b = Math.sin(rad); c = -b; d = a; e = 0; f = 0;
          break;
          case "skewX":
            a = 1; b = 0; c = Math.tan(rad); d = 1; e = 0; f = 0;
          break;
          case "skewY":
            a = 1; b = Math.tan(rad); c = 0; d = 1; e = 0; f = 0;
          break;
          }
        }
      }
      matri = new Matrix(a,b,c,d,e,f);
      matrix = matrix.multiply(matri);
      lis = com = deg = rad = null;
    }
    list = coma = mat = matri = null;
  }
  }  catch(e) {stlog.add(e,816);}
  return matrix;
};

//SVGPointを参照
function Point( /*number*/ x, /*number*/ y) {
  this.x = x; this.y = y;
  return this;
}
Point.prototype.matrixTransform = function ( /*Matrix*/ m) {
  var x = parseInt(m.a * this.x + m.c * this.y + m.e);
  var y = parseInt(m.b * this.x + m.d * this.y + m.f);
  if (-1 < x && x < 1) {x=1;}
  if (-1 < y && y < 1) {y=1;}
  var s = new Point(x,y);
  return s;
};

//Pointのリスト。一括で処理できる
function PList( /*Array*/ d) {
  this.list = d;
  return this;
}
PList.prototype.matrixTransform = function plmatrixtransform( /*Matrix*/ ttm) {
  var F = this.list;
  for (var i = 0, Fli = F.length; i < Fli;) {
    if (isNaN(F[i])) { //コマンド文字は読み飛ばす
      ++i;
      continue;
    }
    var p = new Point(parseFloat(F[i]), parseFloat(F[i+1]));
    var pmt = p.matrixTransform(ttm);
    F[i++] = pmt.x;
    F[i++] = pmt.y;
    p = pmt = null;
  }
  var s = new PList(F);
  return s;
}

//SVGMatrixを参照。行列
function Matrix(a,b,c,d,e,f) { //引数はすべてNumber型
  this.a = a; this.b = b; this.c = c; this.d = d; this.e = e; this.f = f;
  return this;
}
//Matrix同士の積を算出
Matrix.prototype.multiply = function ( /*Matrix*/ m) {
  var s = new Matrix(this.a * m.a + this.c * m.b,this.b * m.a + this.d * m.b,this.a * m.c + this.c * m.d,this.b * m.c + this.d * m.d,this.a * m.e + this.c * m.f + this.e,this.b * m.e + this.d * m.f + this.f);
  return s;
};
//行列式
Matrix.prototype.determinant = function() {
  return (this.a * this.d - this.b * this.c);
};

//SVGViewSpecを参照
function STViewSpec( /*element*/ ele) {
  this.tar = ele;
  var vb = ele.getAttribute("viewBox");
  if (vb) {
    var ovb = vb.replace(/^\s+|\s+$/g, "").split(/[\s,]+/);
    this.viewBox = new STRect(parseFloat(ovb[0]), parseFloat(ovb[1]), parseFloat(ovb[2]), parseFloat(ovb[3]));
  } else {
    this.viewBox = null;
  }
  var par = ele.getAttribute("preserveAspectRatio") || "xMidYMid meet";
  var sa = 1, mos = 0;
  if (par.match(/x(Min|Mid|Max)Y(Min|Mid|Max)(?:\s+(meet|slice))?/)) {
    switch (RegExp.$1) {
      case "Min":
        sa += 1;
      break;
      case "Mid":
        sa += 2;
      break;
      case "Max":
        sa += 3;
      break;
    }
    switch (RegExp.$2) {
      case "Min":
      break;
      case "Mid":
        sa += 3;
      break;
      case "Max":
        sa += 6;
      break;
    }
    if (RegExp.$3 === "slice") {
      mos = 2;
    } else {
      mos = 1;
    }
  }
  this.preserveAspectRatio = new STPreserveAspectRatio(sa, mos);
  vb = par = null;
  return this;
}
STViewSpec.prototype.set = function vss( /*float*/ vw, /*float*/ vh, /*element*/ ob) {
  var vB = this.viewBox, par = this.preserveAspectRatio;
  try {
  if (!vB) {
    this._tx = this._ty = 0;
    return new Matrix(1, 0, 0, 1, 0, 0);
  }
  var vbx = vB.x, vby = vB.y, vbw = vB.width, vbh = vB.height;
  var rw = vw / vbw, rh = vh / vbh;
  var xr = 1, yr = 1, tx = 0, ty = 0;
  if (par.align === 1) { //none
    xr = rw;
    yr = rh;
    tx = -vbx * xr;
    ty = -vby * yr;
  } else {
    var ax = (par.align + 1) % 3 + 1;
    var ay = Math.round(par.align / 3);
    switch (par.meetOrSlice) {
      case 1: //meet
        xr = yr = Math.min(rw, rh);
      break;
      case 2: //slice
        xr = yr = Math.max(rw, rh);
      break;
    }
    tx = -vbx * xr;
    ty = -vby * yr;
    switch (ax) {
      case 1: //xMin
      break;
      case 2: //xMid
        tx += (vw - vbw * xr) / 2;
      break;
      case 3: //xMax
        tx += vw - vbw * xr;
      break;
    }
    switch (ay) {
      case 1: //YMin
      break;
      case 2: //YMid
        ty += (vh - vbh * yr) / 2;
      break;
      case 3: //YMax
        ty += vh - vbh * yr;
      break;
    }
  }
  var ttps =  ob.style;
  this._tx = tx;
  this._ty = ty;
  ttps.marginLeft = this._tx+ "px";
  ttps.marginTop = this._ty+ "px";
  var m = new Matrix(xr, 0, 0, yr, 0, 0);
  return m;
  } catch(e) {stlog.add(e,1031);}
}

//SVGRectを参照
function STRect(x,y,w,h) { //引数はすべてNumber型
  this.x = x; this.y = y;
  this.width = w; this.height = h;
  return this;
}

//SVGPreserveAspectRatioを参照
function STPreserveAspectRatio( /*int*/ a, /*int*/ mos) {this.align=a;this.meetOrSlice=mos;
  return this;
}

//path要素のd属性で使われるA（rcTo）コマンドを処理
function STArc() {
  return this;
}
STArc.prototype.matrixTransform = function arcmatrixTransform( /*Matrix*/ matrix) {
  var plst = new PList(this.D);
  var s = new STArc();
  s.D = plst.matrixTransform(matrix).list;
  plst = null;
  return s;
}
//2つの点から角度を算出
STArc.prototype.CVAngle = function starccvangle(ux,uy,vx,vy) {
  var rad = Math.atan2(vy, vx) - Math.atan2(uy, ux);
  return (rad >= 0) ? rad : 2 * Math.PI + rad;
}
//弧をベジェ曲線に変換
STArc.prototype.set = function starcset(x1,y1,rx,ry,psai,fA,fS,x4,y4) {
  var fS = parseFloat(fS),  rx = parseFloat(rx),  ry = parseFloat(ry),  psai = parseFloat(psai),  x1 = parseFloat(x1),  x4 = parseFloat(x4),  y1 = parseFloat(y1),  y4 = parseFloat(y4);
  if (rx === 0 || ry === 0) {throw "line";}
  rx = Math.abs(rx); ry = Math.abs(ry);
  var ccx = (x1 - x4) / 2,  ccy = (y1 - y4) / 2;
  var cpsi = Math.cos(psai*Math.PI/180),  spsi = Math.sin(psai*Math.PI/180);
  var x1d = cpsi*ccx + spsi*ccy,  y1d = -1*spsi*ccx + cpsi*ccy;
  var x1dd = x1d * x1d, y1dd = y1d * y1d;
  var rxx = rx * rx, ryy = ry * ry;
  var lamda = x1dd/rxx + y1dd/ryy;
  var sds;
  if (lamda > 1) {
    rx = Math.sqrt(lamda) * rx;
    ry = Math.sqrt(lamda) * ry;
    sds = 0;
  }  else{
    var seif = 1;
    if (fA === fS) {
      seif = -1;
    }
    sds = seif * Math.sqrt((rxx*ryy - rxx*y1dd - ryy*x1dd) / (rxx*y1dd + ryy*x1dd));
  }
  var cxd = sds*rx*y1d / ry,  cyd = -1 * sds*ry*x1d / rx;
  var cx = cpsi*cxd - spsi*cyd + (x1+x4)/2, cy = spsi*cxd + cpsi*cyd + (y1+y4)/2;
  var s1 = this.CVAngle(1,0,(x1d-cxd)/rx,(y1d-cyd)/ry);
  var dr = this.CVAngle((x1d-cxd)/rx,(y1d-cyd)/ry,(-x1d-cxd)/rx,(-y1d-cyd)/ry);
  if (!fS  &&  dr > 0) {
    dr -=   2*Math.PI;
  } else if (fS  &&  dr < 0) {
    dr += 2*Math.PI;
  }
  var sse = dr * 2 / Math.PI;
  var seg = Math.ceil(sse<0 ? -1*sse  :  sse);
  var segr = dr / seg;
  var nea = [];
  var t = 8/3 * Math.sin(segr/4) * Math.sin(segr/4) / Math.sin(segr/2);
  var cpsirx = cpsi * rx;
  var cpsiry = cpsi * ry;
  var spsirx = spsi * rx;
  var spsiry = spsi * ry;
  var mc = Math.cos(s1);
  var ms = Math.sin(s1);
  var x2 = x1 - t * (cpsirx * ms + spsiry * mc);
  var y2 = y1 - t * (spsirx * ms - cpsiry * mc);
  for (var i = 0; i < seg; ++i) {
    s1 += segr;
    mc = Math.cos(s1);
    ms = Math.sin(s1);
    var x3 = cpsirx * mc - spsiry * ms + cx;
    var y3 = spsirx * mc + cpsiry * ms + cy;
    var dx = -t * (cpsirx * ms + spsiry * mc);
    var dy = -t * (spsirx * ms - cpsiry * mc);
    nea = nea.concat([x2, y2, x3 - dx, y3 - dy, x3, y3]);
    x2 = x3 + dx;
    y2 = y3 + dy;
  }
  this.D = (this.D ? this.D.concat(nea) : nea);
  nea = null;
  return true;
}
//setをできるだけ繰り返す
STArc.prototype.sset = function starcsset( /*float*/ nox, /*float*/ noy, /*array*/ f, /*float*/ rx, /*float*/ ry) {
  for (var i=1,fli=f.length;i<fli+1;i+=7){
    this.set(nox,noy,f[i],f[i+1],f[i+2],f[i+3],f[i+4],f[i+5]+rx,f[i+6]+ry);
    nox = f[i+5]+rx; noy = f[i+6]+ry;
  }
}

//SVGLengthを参照
function STLength( /*string or number*/ d, /*float*/ wort, /*float*/ f) {
  d += "";
  this.unitType = 0; //unknown
  if (wort === void 0) { //void 0 = undefined
    wort = 1;
  }
  if (f === void 0) {
    f = 12;
  }
  try {
  this._n[1] *= wort;
  this._n[2] = this._n[3] = f;
  var v = parseFloat(d);
  var tani = d.match(this._dR);
  var ut = 1;
  if(tani) {
    ut = this._tani[tani];
  }
  this.newValueSpecifiedUnits(ut,v);
  d = wort = f = v = tani = ut = null; //解放
  }  catch(e) {stlog.add(e,1133); this.value = 1000;}
  return this;
}
STLength.prototype._dR = /\D+$/; //RegExpオブジェクトをあらかじめ生成
STLength.prototype._n = [1, 0.01, 1, 1, 1, 35.43307, 3.543307, 90, 1.25, 15]; //利用単位への変換値
STLength.prototype._tani = { //単位に番号を振る
  "pt": 9,
  "pc": 10,
  "mm": 7,
  "cm": 6,
  "in": 8,
  "em": 3,
  "ex": 4,
  "px": 5,
  "%":  2
}
STLength.prototype.newValueSpecifiedUnits = function ( /*number*/ ut, /*number*/ value) {
  this.unitType = ut;
  this.value = value * this._n[ut-1];
  this.valueInSpecifiedUnits = value;
  this._n[1] = 0.01; //初期化
};
//XLink言語を処理
NAIBU.XLink = function( /*element*/ ele) {
  this.tar = ele;
  var href = ele.getAttribute("xlink:href");
  if (href) { //xlink:href属性が指定されたとき
    this.show = ele.getAttribute("xlink:show");
    var base;
    var egbase = ele.getAttribute("xml:base");
    if (!egbase) {
      var ep = ele.parentNode, b = null;
      while(!b  &&  ep.tagName === "group") {
        b = ep.getAttribute("xml:base");
        if (b) {
          break;
        }
        ep = ep.parentNode;
      }
      base = b;
      if (!b) { //xml:baseの指定がなければ
        if (href.indexOf("#") !== 0) { //href属性において#が一番につかない場合
          var lh = location.href;
          base = lh.replace(/\/[^\/]+?$/,"/"); //URIの最後尾にあるファイル名は消す。例: /n/sie.js -> /n/
        } else{
          base = location.href;
        }
      }
    } else{
    base = egbase;
    }
    if (href.indexOf(":") === -1) {
      this.base = base;
    }  else{
      this.base  ="";
    }
    this.href = href;
  } else {
    this.href = null;
  }
  return this;
}
NAIBU.XLink.prototype.set = function() {
  try {
  if (this.href) {
    var uri = this.base + this.href;
    if (this.href.indexOf(".") === 0) { //相対URIの場合
      uri = this.href;
    }
    switch (this.show) {
      case "embed":
        if (this.tar.tagName === "image") {
          this.tar.src = uri;
        }  else{
          uri.match(/#(.+)$/);
          this.resource = document.getElementById(RegExp.$1);
          this.tar.innerHTML = this.resource.outerHTML.replace(/<\/?v\:(fill|stroke)>/g, "");
        }
      break;
      case "new":
        this.tar.setAttribute("target","_blank");
      break;
    }
    this.tar.setAttribute("href",uri);
  }
  } catch(e) {stlog.add(e,17155);}
}

function utf16( /*string*/ s)  {
  return unescape(s);
}
function unescapeUTF16( /*string*/ s) {
  return s.replace(/%u\w\w\w\w/g,  utf16);
}

//Text2SVG機能。SVGのソース（文章）をSVG画像に変換できる。（必須ではない）
function textToSVG( /*string*/ source, /*float*/ w, /*float*/ h) {
  var data = 'data:image/svg+xml,' + unescapeUTF16(escape(source));
  var ob = document.createElement("object");
  ob.setAttribute("data",data);
  ob.setAttribute("width",w);
  ob.setAttribute("height",h);
  ob.setAttribute("type","image/svg+xml");
  return ob;
}

//XMLHttpRequestオブジェクトの作成
function HTTP() {
  var xmlhttp;
  try {
    xmlhttp = new ActiveXObject("Msxml2.XMLHTTP");
  } catch (e) {
    try {
      xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
    } catch (E) {
      xmlhttp = false;
    }
  }
  if (!xmlhttp) {
    try {
      xmlhttp = new XMLHttpRequest();
    } catch (e) {
      xmlhttp = false;
    }
  }
  return xmlhttp;
}
var success = true;

//IE用。object要素のデータからVMLを作成
function ca( /*object*/ data) {
if (success  &&  data.success) {
  try {
    var obj = data.obj[data.num-1];
    var obw = new STLength(obj.getAttribute("width"),obj.clientWidth),  obh = new STLength(obj.getAttribute("height"),obj.clientHeight);
    var obwidth = obw.value, obheight = obh.value;
  } catch(e) {stlog.add(e,1209);}
  //正規表現でソースをVML用に書き換え
  //xmlns属性削除はバグが起きないように必須
  var dc = data.content
    .replace(/<!DOCTYPE/, "<!--")
    .replace(/(?:dtd">|\]>)/, "-->")
    .replace(/<\?[^>]+\?>/g, "")
    .replace(/<!\[CDATA\[/g, "<!--")
    .replace(/\]\]>/g, "-->")
    .replace(/xmlns="[^"]+"/g, "")
    .replace(/<svg(?=\s|>)/g, "<v:group")
    .replace(/\/svg>/g, "/v:group>")
    .replace(/<path\s/g, '<v:shape tag="path" ')
    .replace(/\/path>/g, "/v:shape>")
    .replace(/<rect\s/g, '<v:shape tag="rect" ')
    .replace(/\/rect>/g, "/v:shape>")
    .replace(/<line\s/g, '<v:shape tag="line" ')
    .replace(/\/line>/g, "/v:shape>")
    .replace(/<circle\s/g, '<v:shape tag="circle" ')
    .replace(/\/circle>/g, "/v:shape>")
    .replace(/<ellipse\s/g, '<v:shape tag="ellipse" ')
    .replace(/\/ellipse>/g, "/v:shape>")
    .replace(/<polyline\s/g, '<v:shape tag="polyline" ')
    .replace(/\/polyline>/g, "/v:shape>")
    .replace(/<polygon\s/g, '<v:shape tag="polygon" ')
    .replace(/\/polygon>/g, "/v:shape>")
    .replace(/<text(?=\s|>)/g, "<div")
    .replace(/\/text>/g, "/div>")
    .replace(/<g(?=\s|>)/g, "<v:group")
    .replace(/\/g>/g, "/v:group>")
    .replace(/<linearGradient\s/g, '<v:fill type="gradient" ')
    .replace(/\/linearGradient>/g, "/v:fill>")
    .replace(/<radialGradient\s/g, '<v:fill type="gradientRadial" ')
    .replace(/\/radialGradient>/g, "/v:fill>")
    .replace(/fill-/g, "fill")
    .replace(/stroke-/g, "stroke")
    .replace(/stop-/g, "stop")
    .replace(/\bwidth=/g, "svgwidth=")
    .replace(/\bheight=/g, "svgheight=")
    .replace(/<tspan\s/g, "<span ")
    .replace(/\/tspan>/g, "/span>")
    .replace(/<image\s/g, "<v:image ")
    .replace(/\/image>/g, "/v:image>")
    .replace(/<use\s/g, "<use /><v:group ")
    .replace(/\/use>/g, "/v:group>")
    .replace(/<defs(?=\s|>)/g, "<dn:defs")
    .replace(/\/defs>/g, "/dn:defs>");
  var ob = document.createElement("v:group");
  var obst = ob.style;
  ob.innerHTML = dc;
  data = dc = null;
  var obc = ob.getElementsByTagName("group").item(0);  //obcはSVGのルート要素
  var regaw = obc.getAttribute("svgwidth") || obwidth;
  var regah = obc.getAttribute("svgheight") || obheight;
  var regw = new STLength(regaw,obwidth);
  var regh = new STLength(regah,obheight);
  var regwv = regw.value,  reghv = regh.value;
  obst.width = regwv+ "px";
  obst.height = reghv+ "px";
  ob.coordsize = regwv  +" "+  reghv;
  var STdocument = new SVGtoVML(obc,obwidth,obheight,regw,regh);
  obj.parentNode.insertBefore(ob,obj);
  STdocument.read(ob);
  STdocument.set(ob);
  STdocument = obw = obh = regw = regh = null;
  NAIBU.PaintColor.prototype.cache = {}; //キャッシュの初期化
  if (NAIBU.STObject !== void 0) {NAIBU.STObject.next();}
}
}

//指定したURLの文章データを取得
function getURL( /*string*/ url, /*function*/ fn, /*Array*/ ob, /*int*/ n) {  
  var xmlhttp= new HTTP();
  if (xmlhttp) {
    var obn = ob[n-1];
    obn.style.display = "none";
    xmlhttp.open("GET",url,true);
    xmlhttp.setRequestHeader("X-Requested-With", "XMLHttpRequest");
    xmlhttp.onreadystatechange = function() {
      if (xmlhttp.readyState === 4  &&  xmlhttp.status === 200) {
        fn({success:true,content:xmlhttp.responseText,obj:ob,num:n});
        xmlhttp = null;
      }
    }
    xmlhttp.send(null);
  } else {
    fn({success:false});
  }
}

//Sieb用
if (sieb_s) {svgtovml();}
