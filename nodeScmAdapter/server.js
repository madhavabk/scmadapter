var express = require('express');
var app = express();
var fs = require("fs");
var spawn = require('child_process').exec;
var svn = require('node-svn-ultimate');
var mkdirp = require('mkdirp');
var path = require('path');
require('shelljs/global');
var events = require('events');
var EventEmitter = events.EventEmitter;
var flowControl = new EventEmitter();

var child;

var bodyParser = require('body-parser');
var multer  = require('multer');

app.use(express.static('public'));
app.use(bodyParser.urlencoded({ extended: false }));
app.use(multer({ dest: '/tmp/'}));
// For setting view engine
app.set('view engine', 'hbs');
app.set('views', './');

app.get('/', function (req, res) {
   res.sendFile( __dirname + "/" + "index.html" );
})

function patchIt( req, res, list ) {
   console.log("Now running patch command..."); 
   var patch = exec("cd " + req.body.revid + "; patch -p0 -b < ../diffs/" + req.body.revid + ".diff");
}

//This function converts files from dos to unix format if they have long end of line chars
function dos2unix(file) {
    var cmd = "fromdos " + file;
    console.log("dos2unix:" + file );
    exec('file ' + file, function(code, output) {
        if( output.search(/dos/i) != -1 || output.search(/with CRLF line terminators/) != -1 ) {
            console.log("converting dos2unix for: " + cmd );
            var out = exec(cmd, { async:true});
            out.on('error', function(error) {
                console.log("failed for dos2unix: " + error );
            });
        }
    });
}

function processFiles( req, res , list) {
   //console.log(req.files.patch.name);
   //console.log(req.files.patch.path);

   var file = __dirname + "/" + "/diffs/" + req.body.revid + ".diff";
   var data = fs.readFileSync( req.files.patch.path);
   fs.writeFileSync(file, data);
   var split = exec("splitdiff -a " + file);
   console.log("now grepping in " + file );
   var response;
   exec('grep -e \'^+++\' -e \'^---\' ' + file, function(error, stdout, stderr) {
       console.log(stdout);
       files = stdout.split("\n");
       response = { message:'Patch processed successfully', files:'' }; 
       files.forEach(function(file, i) {
           file=file.split(/[\s]/);
           console.log("File:"+ file);
           if(file[0].indexOf('\-\-\-') != -1) {
               if(i == 0 ) {
                   response.files = response.files + "[" + "{ file:'" + file[1] + "'},";
               } else {
                   response.files = response.files + "{ file:'" + file[1] + "'},";
               }    
               console.log("Type: Predecessor " + "Name: " + file[1] + " revision: " + file[3].split("\)")[0]);
               mkdirp.sync(__dirname + "/" + req.body.revid + "/" + path.dirname(file[1]));
               //var fd = fs.openSync(__dirname + "/" + req.body.revid + "/" + file[1], 'wx');
               svn.commands.cat(req.body.repo + "/" +  file[1],{ username: req.body.user, password: req.body.pwd, trustServerCert: true, revision: file[3].split("\)")[0]}, function(err, obj) {
                   console.log("Getting file from SVN:" + file[1]);
                   fs.writeFile(__dirname + "/" + req.body.revid + "/" + file[1], obj, function(err) {
                       console.log("Writing snv content to file:" + file[1]);
                       dos2unix(__dirname + "/" + req.body.revid + "/" +  file[1]);
                   }); // End of write file
               }); //End of svn cat
           } else if(file[0].indexOf('\+\+\+') != -1) {
               console.log("Type: Candidate " + "Name: " + file[1] + " revision: " + file[3].split("\)")[0]);
           }
       });    
       response.files = response.files.replace(/,\s*$/, "");
       response.files = response.files + "]";
       console.log("Final response:" + response.files);
       list = eval(response.files);
       res.render('sbs', { 'title': req.body.revid, files: list});
   }) 
    return {
        then: function(req, res, list) {
            console.log("Calling patchIt  now ...");
            setTimeout( function() {
            patchIt( req, res, list );
        }
    , 4000 * 5) }};
}

app.post('/file-upload', function(req, res) {
    var list;
    processFiles(req, res, list).then(req, res, list)
});

var server = app.listen(8091, function () {

  var host = server.address().address
  var port = server.address().port

  console.log("Example app listening at http://%s:%s", host, port)

})
