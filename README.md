# Cordova ResearchKit Plugin
by [Eddy Verbruggen](http://twitter.com/eddyverbruggen)


<img src="img/researchkit-icon_2x.png" width="97px" height="106px"/>


###IMPORTANT notes:

* This plugin does not currently work in the simulator because of missing framework slices. Use a real device.
* Installation warning: after `cordova plugin add ..` go to TARGET > GENERAL > EMBEDDED BINARIES > + > ResearchKit.framework (see https://github.com/researchkit/researchkit#gettingstarted)



###Supported survey answer formats
At the moment this plugin can only be used for surveys / questionnaires, the supported answer formats currently are:

* ORKBooleanAnswerFormat (user must choose yes/no)
<img src="img/answerformats/BooleanAnswerFormat.png" width="200px" height="356px"/>

* ORKNumericAnswerFormat (user must enter a number)
<img src="img/answerformats/NumericAnswerFormat.png" width="200px" height="356px"/>

* More will be added soon!
