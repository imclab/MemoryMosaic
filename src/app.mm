/*
 *  app.mm
 *  part of app
 *
 *  Created by Parag K Mital on 11/12/10.
 app
 LICENCE
 
 app "The Software" © Parag K Mital, parag@pkmital.com
 
 The Software is and remains the property of Parag K Mital
 ("pkmital"). The Licensee will ensure that the Copyright Notice set
 out above appears prominently wherever the Software is used.
 
 The Software is distributed under this Licence: 
 
 - on a non-exclusive basis, 
 
 - solely for non-commercial use in the hope that it will be useful, 
 
 - "AS-IS" and in order for the benefit of its educational and research
 purposes, pkmital makes clear that no condition is made or to be
 implied, nor is any representation or warranty given or to be
 implied, as to (i) the quality, accuracy or reliability of the
 Software; (ii) the suitability of the Software for any particular
 use or for use under any specific conditions; and (iii) whether use
 of the Software will infringe third-party rights.
 
 pkmital disclaims: 
 
 - all responsibility for the use which is made of the Software; and
 
 - any liability for the outcomes arising from using the Software.
 
 The Licensee may make public, results or data obtained from, dependent
 on or arising out of the use of the Software provided that any such
 publication includes a prominent statement identifying the Software as
 the source of the results or the data, including the Copyright Notice
 and stating that the Software has been made available for use by the
 Licensee under licence from pkmital and the Licensee provides a copy of
 any such publication to pkmital.
 
 The Licensee agrees to indemnify pkmital and hold them
 harmless from and against any and all claims, damages and liabilities
 asserted by third parties (including claims for negligence) which
 arise directly or indirectly from the use of the Software or any
 derivative of it or the sale of any products based on the
 Software. The Licensee undertakes to make no liability claim against
 any employee, student, agent or appointee of pkmital, in connection 
 with this Licence or the Software.
 
 
 No part of the Software may be reproduced, modified, transmitted or
 transferred in any form or by any means, electronic or mechanical,
 without the express permission of pkmital. pkmital's permission is not
 required if the said reproduction, modification, transmission or
 transference is done without financial return, the conditions of this
 Licence are imposed upon the receiver of the product, and all original
 and amended source code is included in any transmitted product. You
 may be held legally responsible for any copyright infringement that is
 caused or encouraged by your failure to abide by these terms and
 conditions.
 
 You are not permitted under this Licence to use this Software
 commercially. Use for which any financial return is received shall be
 defined as commercial use, and includes (1) integration of all or part
 of the source code or the Software into a product for sale or license
 by or on behalf of Licensee to third parties or (2) use of the
 Software or any derivative of it for research with the final aim of
 developing software products for sale or license to a third party or
 (3) use of the Software or any derivative of it for research with the
 final aim of developing non-software products for sale or license to a
 third party, or (4) use of the Software to provide any service to an
 external organisation for which payment is received. If you are
 interested in using the Software commercially, please contact pkmital to
 negotiate a licence. Contact details are: parag@pkmital.com
 
 
 
 * try different features such as pitch, loudness, and spectral flux
 * UI feedback for touchdown events, only act on up
 
 *
 */

#import <mach/mach.h> 
#import <mach/mach_host.h>
#include "pkmAudioWindow.h"
#include "app.h"

int button1_x = 50;
int button1_y = 250;
int button2_x = 190;
int button2_y = 250;
int button3_x = 330;
int button3_y = 250;
int button_width = 110;
const int button_height = 57;

const int checkbox1_x = 60;
const int checkbox1_y = 75;
const int checkbox_size = 25;
bool checkbox1 = true;

int slider0_x = 60;
const int slider0_y = 105;//95;
int slider1_x = 60;
const int slider1_y = 1045;
int slider2_x = 60;
const int slider2_y = 185;//195;
int slider_width = 360;
float slider0_position = 0;
float slider1_position = 0;
float slider2_position = 0;

const int animationtime = 150;
const int segmentationtime = 5;

int SCREEN_WIDTH = 360;
int SCREEN_HEIGHT = 480;

const float maxVoices = 10;

#import "mach/mach.h"

vm_size_t usedMemory(void) {
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
    return (kerr == KERN_SUCCESS) ? info.resident_size : 0; // size in bytes
}

vm_size_t freeMemory(void) {
    mach_port_t host_port = mach_host_self();
    mach_msg_type_number_t host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    vm_size_t pagesize;
    vm_statistics_data_t vm_stat;
    
    host_page_size(host_port, &pagesize);
    (void) host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size);
    return vm_stat.free_count * pagesize;
}

void logMemUsage(void) {
    // compute memory usage and log if different by >= 100k
    static long prevMemUsage = 0;
    long curMemUsage = usedMemory();
    long memUsageDiff = curMemUsage - prevMemUsage;
    
    if (memUsageDiff > 100000 || memUsageDiff < -100000) {
        prevMemUsage = curMemUsage;
        NSLog(@"Memory used %7.1f (%+5.0f), free %7.1f kb", curMemUsage/1000.0f, memUsageDiff/1000.0f, freeMemory()/1000.0f);
    }
}

app::~app() 
{
#ifdef DO_RECORD
	audioOutputFileWriter.close();
	audioInputFileWriter.close();
#endif
	audioFileWriter.close();	
    songReader.close();
#ifdef TARGET_OF_IPHONE
    fclose(fp);
#endif
	
	free(output);
	free(buffer);
	free(output_mono);
	free(current_frame);
#ifndef DO_FILEINPUT
    audioDatabaseNormalizer->saveNormalization();
#endif
    
}

//--------------------------------------------------------------
void app::setup()
{
    SCREEN_WIDTH = ofGetHeight();
    SCREEN_HEIGHT = ofGetWidth();
    
    slider0_x = SCREEN_WIDTH * 0.1;
    slider1_x = SCREEN_WIDTH * 0.1;
    slider2_x = SCREEN_WIDTH * 0.1;
    slider_width = SCREEN_WIDTH * 0.8;
    
    button_width = SCREEN_WIDTH * 0.25;
    button1_x = SCREEN_WIDTH * 0.1;
    button2_x = SCREEN_WIDTH * 0.375;
    button3_x = SCREEN_WIDTH * 0.65;
    
    cout << "w: " << SCREEN_WIDTH << " h: " << SCREEN_HEIGHT << endl;
    
	ofxiPhoneSetOrientation(OFXIPHONE_ORIENTATION_LANDSCAPE_RIGHT);
    
    
    bDrawNeedsUpdate = true;
    bOutOfMemory = false;
    bLearning = true;              // memory mosaicing
	bSetup = false;
    bRealTime = true;
    bSemaphore = false;
    bCopiedBackground = false;
    bSyncopated = false;
	bPressed = false;
	bProcessingSong = false;
    bLearningInputForNormalization = true;
    bWaitingForUserToPickSong = bConvertingSong = bLoadedSong = false;
    bDetectedOnset = false;
    sampleRate = 22050;
    frameSize = 1024;
    fftSize = 1024;
    frame = 0;
    currentFile = 0;
    inputSegmentsCounter = 0;
    
    bMovingSlider0 = bMovingSlider1 = bMovingSlider2 = false;
    
    
#ifdef TARGET_OF_IPHONE
    documentsDirectory = ofxiPhoneGetDocumentsDirectory();
	// delete previous files
    NSString *folderPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]; 
    NSError *error = nil;
    for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:&error]) {
        [[NSFileManager defaultManager] removeItemAtPath:[folderPath stringByAppendingPathComponent:file] error:&error];
    }
    
    // add a folder called audio
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"/audio"];
    
    // Create folder
    if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath])
        [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&error]; 
    
	// -------------- INITIALIZE DEBUG OUTPUT -----------
	// Setup file output for debug logging:
    char buf[256];
	sprintf(buf, "log_%2d%2d%4d_%2dh%2dm%2ds.log", ofGetDay(), ofGetMonth(), ofGetYear(),
			ofGetHours(), ofGetMinutes(), ofGetSeconds());
	NSString * filename = [[NSString alloc] initWithCString: buf];
	
	// redirects NSLog to a console.log file in the documents directory.
	NSString *logPath = [documentsDirectory stringByAppendingPathComponent:filename];
	fp = freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding],"a+",stderr);
	
	// initialize picker for itunes library
	itunesStream.allocate(sampleRate, frameSize, 1);
	
	
	// register touch events
	ofRegisterTouchEvents(this);
	
	// iPhoneAlerts will be sent to this.
	ofxiPhoneAlerts.addListener(this);
	
	
//    ofSetWindowShape(SCREEN_WIDTH, SCREEN_HEIGHT);
    myFBO.allocate(SCREEN_WIDTH, SCREEN_HEIGHT);
#else
	ofSetWindowShape(480, 320);
    myFBO.allocate(480, 320);
	ofSetFullscreen(false);
#endif
	
	//ofxiPhoneSetOrientation(OFXIPHONE_ORIENTATION_PORTRAIT);
    
	
	// black
	ofBackground(0,0,0);
	
    smallBoldFont.loadFont("Dekar.ttf", 18, true);
    largeBoldFont.loadFont("Dekar.ttf", 36, true);
    largeThinFont.loadFont("DekarLight.ttf", 36, true);
    smallThinFont.loadFont("DekarLight.ttf", 16, true);
    
	
    background.loadImage("bg.png");
    
    button.loadImage("button.png");
    
    ringBuffer = new pkmCircularRecorder(fftSize, frameSize);
    
    alignedFrame = (float *)malloc(sizeof(float) * fftSize);
    
    zeroFrame = (float *)malloc(sizeof(float) * frameSize);
    memset(zeroFrame, 0, sizeof(float) * frameSize);
    
    current_frame = (float *)malloc(sizeof(float) * frameSize);
    itunes_frame = (float *)malloc(sizeof(float) * frameSize);
    buffer = (float *)malloc(sizeof(float) * frameSize);
    output = (float *)malloc(sizeof(float) * frameSize);
    output_mono = (float *)malloc(sizeof(float) * frameSize);
	
	// does onset detection for matching
    float thresh = 1.0;
    slider1_position = 0.5;
    spectralFlux = new pkmAudioSpectralFlux(frameSize, fftSize, sampleRate);
    spectralFlux->setOnsetThreshold(thresh);
	spectralFlux->setMinSegmentLength(0);
    
	audioDatabase = new pkmAudioSegmentDatabase();
    int k = 1;
	audioDatabase->setK(k);
    audioDatabase->setMaxObjects(5000);
	slider2_position = k/maxVoices;
	
    audioFeature = new pkmAudioFeatures(sampleRate, fftSize);
    
    numFeatures = 36;
    featureFrame = pkm::Mat(1, numFeatures);
    
    audioDatabaseNormalizer = new pkmAudioFeatureNormalizer(numFeatures);
    currentNumFeatures = 0;
    
#ifndef DO_FILEINPUT
    audioDatabaseNormalizer->loadNormalization();
#endif
    
#ifdef DO_PLCA_SEPARATION
    // PLCA SETUP
    bLearnedPLCABackground  = false;
	
	foregroundComponents	= 5;
	backgroundComponents	= 5;
	foregroundIterations	= 100;
	backgroundIterations	= 100;
    
    plca = new pkmPLCA(512, foregroundComponents, backgroundComponents, 1);
    //    plca->setHSparsity(0.2);
    //    plca->setWSparsity(0);
#endif
    
    foreground_features     = (float *)malloc(sizeof(float)*numFeatures);
    currentSegment = pkm::Mat(SAMPLE_RATE / frameSize * 5, frameSize, true);
    currentSegmentFeatures = pkm::Mat(SAMPLE_RATE / frameSize * 5, numFeatures, true);
    
    currentITunesSegment = pkm::Mat(SAMPLE_RATE / frameSize * 5, frameSize, true);
    currentITunesSegmentFeatures = pkm::Mat(SAMPLE_RATE / frameSize * 5, numFeatures, true);
    
	animationCounter = 0;
    segmentationCounter = segmentationtime;
	
    maxiSettings::setup(sampleRate, 1, frameSize);
    
    ifstream f;
	f.open(ofToDataPath("audio_database.mat").c_str());
	bMatching = f.is_open();
    f.close();
    
    if (!bMatching) {
        printf("Building database\n");
        setupBuilding();
        //OF_EXIT_APP(0);
    }
    
    //bMatching = true;
    
#ifdef DO_RECORD
#ifdef TARGET_OF_IPHONE
	string strDocumentsDirectory = ofxNSStringToString(documentsDirectory);
#else
	string strDocumentsDirectory = ofToDataPath("", true);
#endif
    
	string strFilename;
	stringstream str,str2;
	
	// setup output
	str << strDocumentsDirectory << "/" << "output_" << ofGetDay() << ofGetMonth() << ofGetYear() 
	<< "_" << ofGetHours() << "_" << ofGetMinutes() << "_" << ofGetSeconds() << ".wav";
	strFilename = str.str();
	output_frame = 0;
	audioOutputFileWriter.open(strFilename, frameSize);
	
	// setup input
	str2 << strDocumentsDirectory << "/" << "input_" << ofGetDay() << ofGetMonth() << ofGetYear() 
	<< "_" << ofGetHours() << "_" << ofGetMinutes() << "_" << ofGetSeconds() << ".wav";
	strFilename = str2.str();
	audioInputFileWriter.open(strFilename, frameSize);
#endif
    
    setupMatching();
    
	ofEnableAlphaBlending();
	ofSetBackgroundAuto(false);
    ofBackground(0);
    
#ifdef DO_FILEINPUT    
    
#else
    bLearningInputForNormalization = true;
	ofSetFrameRate(25);
	ofSoundStreamSetup(2, 1, this, sampleRate, frameSize, 4);
#endif
    
    bSetup = true;
}

void app::setupBuilding()
{
    // get the file names of every audio file
    
    string audio_dir = ofToDataPath("audio");
#ifdef TARGET_OF_IPHONE
    audio_dir = ofxiPhoneGetDocumentsDirectory() + string("audio");
#endif
    dirList.open(audio_dir.c_str());
    numFiles = dirList.listDir();
    if(numFiles == 0)
    {
        printf("[ERROR] No files found in %s\n", audio_dir.c_str());
        //        OF_EXIT_APP(0);
    }
    else {
        printf("[OK] Read %d files\n", numFiles);
    }
    audioFiles = dirList.getFiles();
    int currentNumFeatures = 0;
    int lastNumFeatures = 0;
    
    // process input files to segments
    for(vector<ofFile>::iterator it = audioFiles.begin(); it != audioFiles.end(); it++)
    {
        bLearnedPLCABackground = false;
        songReader.open(it->getAbsolutePath());
        long frame = 0;
        while(frame * frameSize < songReader.mNumSamples && !bOutOfMemory)
        {        
            if(songReader.read(current_frame, frame*frameSize, frameSize))
            {
                // get audio features
                audioFeature->compute36DimAudioFeaturesF(current_frame, foreground_features);
                
                // check for onset
                bDetectedOnset = spectralFlux->detectOnset(audioFeature->getMagnitudes(), audioFeature->getMagnitudesLength());
                
                // do mosaicing
                processInputFrame();
                
                frame++;
            }
            else {
                printf("[ERROR]: Could not read audio file!\n");
            }
        } 
        songReader.close();
        
        /*
         // end of file, let's normalize the features
         currentNumFeatures = audioDatabase->featureDatabase.rows;
         if (currentNumFeatures > lastNumFeatures) {
         pkm::Mat thisDatabase = audioDatabase->featureDatabase.rowRange(lastNumFeatures, currentNumFeatures, false);
         printf("Normalizing database of features for %s: \n", it->getFileName().c_str());
         thisDatabase.print();
         pkmAudioFeatureNormalizer::normalizeDatabase(thisDatabase);
         }
         lastNumFeatures = currentNumFeatures;
         */
    }
    
    //pkmAudioFeatureNormalizer::normalizeDatabase(audioDatabase->featureDatabase);
    //audioDatabase->buildIndex();
    //audioDatabase->save();
    //audioDatabase->saveIndex();
}

void app::setupMatching()
{
    // setup envelopes
    pkmAudioWindow::initializeWindow(frameSize);
    
#ifdef DO_FILEINPUT
    
    // load up target
    printf("Matching target.wav\n");
    string inputFileName;
    if (inputAudioFileReader.open(ofToDataPath("target.wav"))) 
    {
        printf("[OK] Opened target.wav with %lu samples\n", inputAudioFileReader.mNumSamples);
    }
    else {
        printf("Failed to open target.wav, prompting user for target file.\n");
        if(ofxFileDialogOSX::openFile(inputFileName))
        {
            if(!inputAudioFileReader.open(inputFileName))
            {
                printf("Failed to open %s ... exiting.\n", inputFileName.c_str());
                OF_EXIT_APP(0);
            }
        }
        else
        {
            printf("Failed to open %s ... exiting.\n", inputFileName.c_str());
            OF_EXIT_APP(0);
        }
    }
    inputAudioFileFrame = 0;
    
    /*
     // calculate normalization of target
     
     while(inputAudioFileFrame*frameSize < inputAudioFileReader.mNumSamples)
     {
     //printf("inputAudioFileFrame: %ld\n", inputAudioFileFrame);
     inputAudioFileReader.read(current_frame, inputAudioFileFrame*frameSize, frameSize);
     inputAudioFileFrame++;
     //ringBuffer->insertFrame(current_frame);
     //if (ringBuffer->bRecorded) {
     //ringBuffer->copyAlignedData(alignedFrame);
     #ifdef DO_MEAN_MEL_FEATURE
     audioFeature->computeLFCCF(current_frame, foreground_features, numFeatures);
     #else
     audioFeature->computeLFCCF(current_frame, foreground_features, numFeatures);
     #endif
     
     bool isFeatureNan = false;
     for (int i = 0; i < numFeatures; i++) {
     isFeatureNan = isFeatureNan | isnan(foreground_features[i]) | (fabs(foreground_features[i]) > 20);
     }
     
     if (!isFeatureNan) {
     //printf(".");
     audioDatabaseNormalizer->addExample(foreground_features, numFeatures);
     }
     //}
     }
     audioDatabaseNormalizer->calculateNormalization();
     */
    
    audioOutput = pkm::Mat(inputAudioFileFrame, frameSize);
    
    inputAudioFileFrame = 0;
#endif
    
    //audioDatabase->load();
    //audioDatabase->loadIndex();
}

//--------------------------------------------------------------
void app::update()
{
#ifdef DO_FILEINPUT
    
    while(inputAudioFileFrame*frameSize < inputAudioFileReader.mNumSamples)
    {
        inputAudioFileReader.read(current_frame, inputAudioFileFrame*frameSize, frameSize);
        
        if (bLearning) {
            processInputFrame(current_frame, frameSize);
        }
        
        audioRequested(current_frame, frameSize, 1);
        
        inputAudioFileFrame++;
    }
    
    /*
     // compress result
     for (long i = 0; i < inputAudioFileFrame; i++) {
     for (int j = 0; j < frameSize; j++) {
     audioOutput.data[i*frameSize + j] = compressor.compressor(audioOutput.data[i*frameSize + j], 0.5);
     }
     // and save 
     #ifdef DO_RECORD
     audioOutputFileWriter.write(audioOutput.row(i), i*frameSize, frameSize);
     #endif
     }
     */
    
    printf("[OK] Finished processing file.  Exiting.\n");
    OF_EXIT_APP(0);
#endif
    
#ifdef TARGET_OF_IPHONE
    if (bWaitingForUserToPickSong && itunesStream.isSelected())
    {
        bWaitingForUserToPickSong = false;
        bProcessingSong = false;
        bConvertingSong = true;
        itunesStream.setStreaming();
        printf("[OK]\n");
        bDrawNeedsUpdate = true;
        printf("Loaded user selected song!\n");
    }
    else if(bWaitingForUserToPickSong && itunesStream.didCancel())
    {
        bWaitingForUserToPickSong = false;
        printf("[OK]\n");
        bDrawNeedsUpdate = true;
        printf("User canceled!\n");
        
    }
    else if(bConvertingSong && itunesStream.isPrepared())
    {
        bConvertingSong = false;
        itunesFrame = 1;
        bProcessingSong = true;
        bDrawNeedsUpdate = true;
    }
#endif
    
    //cout << "size: " << audioDatabase->getSize() << endl;
}

// scrub memory using a cataRT display
// 2 dimensions... pca reprojection of the mfccs? kd-tree?

void app::drawInfo()
{
		
    ofEnableAlphaBlending();
    ofSetColor(255, 255, 255, (float)(animationtime-animationCounter)/(animationtime/2.0f)*255.0f);
    smallBoldFont.drawString("this app resynthesizes your sonic world", SCREEN_WIDTH / 2.0 - smallBoldFont.stringWidth("this app resynthesizes your sonic world") / 2.0, 135);
    smallBoldFont.drawString("using the sound from your microphone and", SCREEN_WIDTH / 2.0 - smallBoldFont.stringWidth("using the sound from your microphone and") / 2.0, 165);
    smallBoldFont.drawString("songs you teach it from your iTunes Library", SCREEN_WIDTH / 2.0 - smallBoldFont.stringWidth("songs you teach it from your iTunes Library") / 2.0, 195);
    ofDisableAlphaBlending();
    
}


void app::drawCheckboxes()
{
	ofNoFill();
    ofSetColor(180, 140, 140);
	
	smallBoldFont.drawString("syncopation", checkbox1_x, checkbox1_y + 45);
	
    ofSetColor(180, 180, 180);
	ofRect(checkbox1_x, checkbox1_y, checkbox_size, checkbox_size);
	if (checkbox1) {
		ofLine(checkbox1_x, checkbox1_y, checkbox1_x+25, checkbox1_y+25);
		ofLine(checkbox1_x+25, checkbox1_y, checkbox1_x, checkbox1_y+25);
	}
}

void app::drawSliders()
{
	ofNoFill();
	ofSetColor(180, 140, 140);
    
    smallBoldFont.drawString("output", slider0_x, slider0_y + 25);
    smallBoldFont.drawString("input", slider0_x + slider_width - smallBoldFont.stringWidth("input"), slider0_y + 25);
    
    smallBoldFont.drawString("0.0", slider1_x, slider1_y + 25);
    smallBoldFont.drawString("1.0", slider1_x + slider_width - smallBoldFont.stringWidth("1.0"), slider1_y + 25);
	
    smallBoldFont.drawString("0.0", slider2_x, slider2_y + 25);
    smallBoldFont.drawString("10.0", slider2_x + slider_width - smallBoldFont.stringWidth("10.0"), slider2_y + 25);
	
    ofFill();
    ofSetColor(255, 255, 255);
    
    if(bProcessingSong)
        smallBoldFont.drawString("song mix", SCREEN_WIDTH / 2.0 - smallBoldFont.stringWidth("song mix") / 2.0, slider0_y + 25);
    else
        smallBoldFont.drawString("microphone mix", SCREEN_WIDTH / 2.0 - smallBoldFont.stringWidth("microphone mix") / 2.0, slider0_y + 25);
	smallBoldFont.drawString("grain size (s)", SCREEN_WIDTH / 2.0 - smallBoldFont.stringWidth("grain size (s)") / 2.0, slider1_y + 25);
    smallBoldFont.drawString("number of voices", SCREEN_WIDTH / 2.0 - smallBoldFont.stringWidth("number of voices") / 2.0, slider2_y + 25);
    
    button.draw(slider0_position*slider_width + slider0_x - 10, slider0_y - 10, 20, 20);
    button.draw(slider1_position*slider_width + slider1_x - 10, slider1_y - 10, 20, 20);
    button.draw(slider2_position*slider_width + slider2_x - 10, slider2_y - 10, 20, 20);
    
	ofLine(slider0_x, slider0_y, slider0_x + slider_width, slider0_y);
    ofLine(slider1_x, slider1_y, slider1_x + slider_width, slider1_y);
    ofLine(slider2_x, slider2_y, slider2_x + slider_width, slider2_y);
}

void app::drawButtons()
{
	ofNoFill();
    ofSetColor(180, 140, 140);
    smallBoldFont.drawString("erase my", button1_x + (button_width - smallBoldFont.stringWidth("erase my")) / 2.0, 275);
    smallBoldFont.drawString("memory", button1_x + (button_width - smallBoldFont.stringWidth("memory")) / 2.0, 295);
    
    if(bProcessingSong)
    {
        smallBoldFont.drawString("stop", button2_x + (button_width - smallBoldFont.stringWidth("stop")) / 2.0, 275);
        smallBoldFont.drawString("processing", button2_x + (button_width - smallBoldFont.stringWidth("processing")) / 2.0, 295);
    }
    else
    {
        smallBoldFont.drawString("choose", button2_x + (button_width - smallBoldFont.stringWidth("choose")) / 2.0, 275);
        smallBoldFont.drawString("a song", button2_x + (button_width - smallBoldFont.stringWidth("a song")) / 2.0, 295);
    }
    
    if (bLearning) {
        smallBoldFont.drawString("stop", button3_x + (button_width - smallBoldFont.stringWidth("stop")) / 2.0, 275);
        smallBoldFont.drawString("learning", button3_x + (button_width - smallBoldFont.stringWidth("learning")) / 2.0, 295);
    }
    else {
        smallBoldFont.drawString("start", button3_x + (button_width - smallBoldFont.stringWidth("start")) / 2.0, 275);
        smallBoldFont.drawString("learning", button3_x + (button_width - smallBoldFont.stringWidth("learning")) / 2.0, 295);
    }
    
    ofSetColor(255);
    ofRect(button1_x, button1_y, button_width, button_height);
    ofRect(button2_x, button2_y, button_width, button_height);
	ofRect(button3_x, button3_y, button_width, button_height);
}

void app::drawWaveform()
{
	ofNoFill();
    // waveform
    int h = SCREEN_HEIGHT;
    int w = SCREEN_WIDTH;
    int numSamplesToDraw	= 15;
    float width_step		= w / numSamplesToDraw;
    float height_factor		= h * 2.0f;
    
    // input waveform
    ofEnableAlphaBlending();
    ofSetColor(255, 255, 255, 170);
    ofPushMatrix();
    ofTranslate(0, h/2.0, 0);
    ofBeginShape();
    ofCurveVertex(w, 0);
    ofCurveVertex(0, 0);
    for (int i = 0; i < numSamplesToDraw; i++) {
        int sub = i * frameSize / (float)numSamplesToDraw;
        ofCurveVertex(i*width_step, buffer[sub]*height_factor);
    }
    ofCurveVertex(w, 0);
    ofCurveVertex(0, 0);
    ofEndShape(true);
    ofPopMatrix();
    ofDisableSmoothing();
    ofDisableAlphaBlending();
}

//--------------------------------------------------------------
void app::draw()
{	
    if (bDrawNeedsUpdate) {
        
        myFBO.begin();
        ofBackground(0);
        ofEnableAlphaBlending();
        ofTranslate(-7, 0, 0);
        ofFill();
        ofSetColor(255, 255, 255);
        //if (animationCounter < 0 || animationCounter > (animationtime/2.0f)) {
		drawButtons();
		drawSliders();
		//drawCheckboxes();
        //}
        
         
        //drawInfo();
        
        ofSetColor(255, 255, 255);
        largeBoldFont.drawString("memory mosaic", SCREEN_WIDTH / 2.0 - largeBoldFont.stringWidth("memory mosaic") / 2.0, 40);
        
        //background.draw(0, 0, w, h);
        
        if (bOutOfMemory) {
            ofEnableAlphaBlending();
            ofSetColor(0, 0, 0, 180);
            ofFill();
            ofRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
            ofNoFill();
            ofSetColor(255, 255, 255);
            smallBoldFont.drawString("No more free memory for learning", SCREEN_WIDTH / 2.0 - smallBoldFont.stringWidth("No more free memory for learning") / 2.0, 290);
        }
        
        else if (bConvertingSong) {
            ofEnableAlphaBlending();
            ofSetColor(0, 0, 0, 180);
            ofFill();
            ofRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
            ofNoFill();
            ofSetColor(255, 255, 255);
            smallBoldFont.drawString("Converting song for processing...", SCREEN_WIDTH / 2.0 - smallBoldFont.stringWidth("Converting song for processing...") / 2.0, 160);
        }
        
//        else if(bProcessingSong) {
//            ofEnableAlphaBlending();
//            ofSetColor(0, 0, 0, 60);
//            ofFill();
//            ofRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
//            ofNoFill();
//            ofSetColor(255, 255, 255);
//            smallBoldFont.drawString("Processing song into memory...", 100, 160);
//        }
//        
//        else
        
        else if(bWaitingForUserToPickSong) {
            ofEnableAlphaBlending();
            ofSetColor(0, 0, 0, 60);
            ofFill();
            ofRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
            ofNoFill();
            ofSetColor(255, 255, 255);
            smallBoldFont.drawString("Loading iTunes Library...", SCREEN_WIDTH / 2.0 - smallBoldFont.stringWidth("Loading iTunes Library...") / 2.0, 160);
        }
        
        
        
        ofSetColor(180, 140, 140);
        string numData = string("size: ") + ofToString(audioDatabase->getSize());
        smallBoldFont.drawString(numData,
                                 SCREEN_WIDTH / 2.0 - smallBoldFont.stringWidth(numData) / 2.0,
                                 70);
        
        ofDisableAlphaBlending();
        
        myFBO.end();
        
        bDrawNeedsUpdate = false;
    }
    
    ofBackground(0);
    ofSetColor(255);
    myFBO.draw(0,0);
    
    if (animationCounter < animationtime) {
        ofEnableAlphaBlending();
        ofSetColor(0, 0, 0, (float)(animationtime-animationCounter)/(animationtime/2.0f)*255.0f);
        ofRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        ofDisableAlphaBlending();
        drawInfo();
        animationCounter++;
    }
    else if(segmentationCounter < segmentationtime) {
        ofEnableAlphaBlending();
        ofSetColor(255, 255, 255, (float)(segmentationtime-segmentationCounter)/(segmentationtime/2.0f)*40.0f);
        ofRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        ofDisableAlphaBlending();
        segmentationCounter++;
    }
    
    /*
     mach_port_t             host_port = mach_host_self();
     mach_msg_type_number_t  host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
     vm_size_t               pagesize;
     vm_statistics_data_t    vm_stat;
     
     host_page_size(host_port, &pagesize);
     
     if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS) NSLog(@"Failed to fetch vm statistics");
     
     natural_t   mem_used    = (vm_stat.active_count + vm_stat.inactive_count + vm_stat.wire_count) * pagesize;
     natural_t   mem_free    = vm_stat.free_count * pagesize;
     natural_t   mem_total   = mem_used + mem_free;
     float       fmem_free   = mem_free / (1024. * 1024.);
     float       fmem_total  = mem_total / (1024. * 1024.);
     
     char buf[256];
     sprintf(buf, "%3.2f/%3.2f", fmem_free, fmem_total);
     smallBoldFont.drawString(buf, 20, 20);
	 */
}

//--------------------------------------------------------------
void app::audioRequested(float * output, int bufferSize,
                         int ch)
{
    bSemaphore = true;
    vector<ofPtr<pkmAudioSegment> >::iterator it;
    
    vDSP_vclr(output_mono, 1, bufferSize);
    vDSP_vclr(buffer, 1, bufferSize);
//    if(!bProcessingSong)
//    {
        // if we detected a segment
        if(bDetectedOnset)
        {
            // find matches
            vector<ofPtr<pkmAudioSegment> > newSegments;
            newSegments = audioDatabase->getNearestAudioSegments(foreground_features);
            int totalSegments = newSegments.size() + nearestAudioSegments.size();
            
            // if we are syncopated, we force fade out of old segments
            if (bSyncopated) {
                it = nearestAudioSegments.begin();
                while( it != nearestAudioSegments.end() ) 
                {
                    
                    //printf("frame: %d\n", ((*it)->onset + (*it)->frame*frameSize) / frameSize);
                    // get frame
    #ifdef DO_FILEBASED_SEGMENTS
                    pkmEXTAudioFileReader reader;
                    reader.open(ofToDataPath((*it)->filename), sampleRate);
                    long sampleStart = (long)(*it)->onset + (long)(*it)->frame*frameSize;
                    reader.read(buffer, 
                                sampleStart, 
                                (long)frameSize, 
                                sampleRate);
                    reader.close();
    #else
                    cblas_scopy(frameSize, (*it)->buffer + (*it)->frame*frameSize, 1, buffer, 1);
    #endif
                    //printf("%s: %ld, %ld\n", (*it)->filename.c_str(), sampleStart, (long)frameSize);
                    (*it)->bPlaying = false;
                    (*it)->frame = 0;
                    it++; 
                    
                    // mix in
                    //vDSP_vsmul(buffer, 1, &level, buffer, 1, fadeLength);
    #ifdef DO_REALTIME_FADING
                    // fade out
                    vDSP_vmul(buffer + frameSize - pkmAudioWindow::rampOutLength, 1, 
                              pkmAudioWindow::rampOutBuffer, 1, 
                              buffer + frameSize - pkmAudioWindow::rampOutLength, 1, 
                              pkmAudioWindow::rampOutLength);
    #endif
                    vDSP_vadd(buffer, 1, output_mono, 1, output_mono, 1, frameSize);
                    
                }
                
                nearestAudioSegments.clear();
            }
            // otherwise we playback old nearest neighbors as normal
            else 
            {
                vector<ofPtr<pkmAudioSegment> >::iterator it = nearestAudioSegments.begin();
                while(it != nearestAudioSegments.end()) 
                {
                    // get frame
    #ifdef DO_FILEBASED_SEGMENTS
                    pkmEXTAudioFileReader reader;
                    reader.open(ofToDataPath((*it)->filename), sampleRate);
                    long sampleStart = (long)(*it)->onset + (long)(*it)->frame*frameSize;
                    reader.read(buffer, 
                                sampleStart, 
                                (long)frameSize, 
                                sampleRate);
                    reader.close();
    #else
                    cblas_scopy(frameSize, (*it)->buffer + (*it)->frame*frameSize, 1, buffer, 1);
    #endif
                    //printf("%s: %ld, %ld\n", (*it)->filename.c_str(), sampleStart, (long)frameSize);
                    (*it)->frame++;
                    
                    // mix in
                    //vDSP_vsmul(buffer, 1, &level, buffer, 1, frameSize);
                    
                    if (((*it)->onset + (*it)->frame*frameSize) >= (*it)->offset) 
                    {
    #ifdef DO_REALTIME_FADING
                        // fade out
                        vDSP_vmul(buffer + frameSize - pkmAudioWindow::rampOutLength, 1, 
                                  pkmAudioWindow::rampOutBuffer, 1, 
                                  buffer + frameSize - pkmAudioWindow::rampOutLength, 1, 
                                  pkmAudioWindow::rampOutLength);
    #endif
                        (*it)->bPlaying = false;
                        (*it)->frame = 0;
                        it = nearestAudioSegments.erase(it);
                    }
                    else if((*it)->bNeedsReset)
                    {
                        // fade out
                        vDSP_vmul(buffer + frameSize - pkmAudioWindow::rampOutLength, 1, 
                                  pkmAudioWindow::rampOutBuffer, 1, 
                                  buffer + frameSize - pkmAudioWindow::rampOutLength, 1, 
                                  pkmAudioWindow::rampOutLength);
                        (*it)->frame = 0;
                        (*it)->bNeedsReset = false;
                        it++;
                    }
                    else
                        it++;                        
                    
                    vDSP_vadd(buffer, 1, output_mono, 1, output_mono, 1, frameSize);
                }
            }
            
            totalSegments = nearestAudioSegments.size();
            
            // fade in new segments and store them for next frame
            it = newSegments.begin(); 
            while( it != newSegments.end() ) 
            {
    #ifdef DO_FILEBASED_SEGMENTS
                pkmEXTAudioFileReader reader;
                reader.open(ofToDataPath((*it)->filename), sampleRate);
                long sampleStart = (long)(*it)->onset + (long)(*it)->frame*frameSize;
                reader.read(buffer, 
                            sampleStart,  // should be 0... 
                            (long)frameSize, 
                            sampleRate);
                reader.close();
    #else
                cblas_scopy(frameSize, (*it)->buffer + (*it)->frame*frameSize, 1, buffer, 1);
                
                cout << (*it)->index << endl;
                
                //audioDatabase->featureDatabase.printAbbrev();
    #endif
                (*it)->frame++;
                (*it)->bPlaying = true;
                
    #ifdef DO_REALTIME_FADING
                // fade in
                vDSP_vmul(buffer, 1, 
                          pkmAudioWindow::rampInBuffer, 1, 
                          buffer, 1, 
                          pkmAudioWindow::rampInLength);
    #endif
                
                // check if segment is ready for fade out, i.e. segment is only "frameSize" samples
                if (((*it)->onset + (*it)->frame*frameSize) >= (*it)->offset) 
                {
    #ifdef DO_REALTIME_FADING
                    // fade out
                    vDSP_vmul(buffer + frameSize - pkmAudioWindow::rampOutLength, 1, 
                              pkmAudioWindow::rampOutBuffer, 1, 
                              buffer + frameSize - pkmAudioWindow::rampOutLength, 1, 
                              pkmAudioWindow::rampOutLength);
    #endif
                    
                    (*it)->bPlaying = false;
                    (*it)->frame = 0;
                    it = newSegments.erase(it);
                }
                // otherwise move to next segment
                else 
                {
                    it++;
                }
                
                // and mix in the faded segment to the stream
                vDSP_vadd(buffer, 1, output_mono, 1, output_mono, 1, frameSize);
            }
            
            // store new segments
            nearestAudioSegments.insert(nearestAudioSegments.end(), newSegments.begin(), newSegments.end());
            
        }
        // no onset, continue playback of old nearest neighbors
        else 
        {
            // loop through all previous neighbors
            vector<ofPtr<pkmAudioSegment> >::iterator it = nearestAudioSegments.begin();
            while(it != nearestAudioSegments.end()) 
            {
    #ifdef DO_FILEBASED_SEGMENTS
                // get audio frame
                pkmEXTAudioFileReader reader;
                reader.open(ofToDataPath((*it)->filename), sampleRate);
                long sampleStart = (long)(*it)->onset + (long)(*it)->frame*frameSize;
                reader.read(buffer, 
                            sampleStart, 
                            (long)frameSize, 
                            sampleRate);
                reader.close();
    #else
                cblas_scopy(frameSize, (*it)->buffer + (*it)->frame*frameSize, 1, buffer, 1);
    #endif
                //printf("%s: %ld, %ld\n", (*it)->filename.c_str(), sampleStart, (long)frameSize);
                
                (*it)->frame++;
                
                // finished playing audio segment?
                if ((*it)->onset + (*it)->frame*frameSize  >= (*it)->offset) 
                {  
    #ifdef DO_REALTIME_FADING
                    // fade out
                    vDSP_vmul(buffer + frameSize - pkmAudioWindow::rampOutLength, 1, 
                              pkmAudioWindow::rampOutBuffer, 1, 
                              buffer + frameSize - pkmAudioWindow::rampOutLength, 1, 
                              pkmAudioWindow::rampOutLength);
    #endif
                    
                    (*it)->bPlaying = false;
                    (*it)->frame = 0;
                    it = nearestAudioSegments.erase(it);
                }
                
                else if((*it)->bNeedsReset)
                {
                    // fade out
                    vDSP_vmul(buffer + frameSize - pkmAudioWindow::rampOutLength, 1, 
                              pkmAudioWindow::rampOutBuffer, 1, 
                              buffer + frameSize - pkmAudioWindow::rampOutLength, 1, 
                              pkmAudioWindow::rampOutLength);
                    (*it)->frame = 0;
                    (*it)->bNeedsReset = false;
                    it++;
                }
                
                // no, keep it for next frame
                else
                    it++;
                
                // mix in
                vDSP_vadd(buffer, 1, output_mono, 1, output_mono, 1, frameSize);
            }
        }
        
        
        // mix in input
    if(bProcessingSong)
    {
        vDSP_vsmul(itunes_frame, 1, &slider0_position, buffer, 1, frameSize);
        float mixR = 1.0f - slider0_position;
        vDSP_vsmul(output_mono, 1, &mixR, output_mono, 1, frameSize);
        vDSP_vadd(buffer, 1, output_mono, 1, output_mono, 1, frameSize);
    }
    else
    {
        vDSP_vsmul(current_frame, 1, &slider0_position, buffer, 1, frameSize);
        float mixR = 1.0f - slider0_position;
        vDSP_vsmul(output_mono, 1, &mixR, output_mono, 1, frameSize);
        vDSP_vadd(buffer, 1, output_mono, 1, output_mono, 1, frameSize);
    }
//    }
//    else
//    {
//        // mix in input
//        float mixR = 1.0f - 0.5;
//        vDSP_vsmul(current_frame, 1, &mixR, buffer, 1, frameSize);
//        vDSP_vsmul(output_mono, 1, &mixR, output_mono, 1, frameSize);
//        vDSP_vadd(buffer, 1, output_mono, 1, output_mono, 1, frameSize);
//    }
	//limiter
	//limiter.Process<float, 1>(frameSize, output_mono);
    //for (int i = 0; i < frameSize; i++) {
    //    output_mono[i] = compressor.compressor(output_mono[i], 1.0, 1.0, 1.0, 1.0);
    //double threshold=0.9, double attack=1, double release=0.9995
    //limiter.Process<float, 1>(1, output_mono+i);
    //}
    
	//clipper
	//float lowClip = -0.999999;
    //float highClip = 0.999999;
    //vDSP_vclip(output_mono, 1, &lowClip, &highClip, output_mono, 1, frameSize);
	
#ifdef DO_RECORD
	audioInputFileWriter.write(current_frame, output_frame*frameSize, frameSize);
	audioOutputFileWriter.write(output_mono, output_frame*frameSize, frameSize);
	output_frame++;
#endif
    
    for (int i = 0; i < frameSize; i++)
    {
        output_mono[i] = compressor.compressor(loresFilter.lores(output_mono[i], 7000, 1.0), 0.5, 0.7, 1.0, 0.9995);
    }
	
	// mix to stereo
    cblas_scopy(frameSize, output_mono, 1, output, 2);
    cblas_scopy(frameSize, output_mono, 1, output+1, 2);
    
    bSemaphore = false;
}

void app::processITunesInputFrame()
{
    // check for max segment
    bool bMaxSegmentReached = currentITunesSegment.isCircularInsertionFull();
    
    // parse segment
    if(bDetectedOnset || bMaxSegmentReached)
    {
        int segmentSize = bMaxSegmentReached ? currentITunesSegment.rows : currentITunesSegment.current_row;
        
        pkm::Mat croppedFeature(segmentSize, numFeatures, currentITunesSegmentFeatures.data, false);
        pkm::Mat meanFeature = croppedFeature.mean();
        //meanFeature.print();
        if (audioDatabase->bShouldAddSegment(meanFeature.data)) 
        {
            currentFile++;
//            // fade in
//            vDSP_vmul(currentITunesSegment.data, 1, 
//                      pkmAudioWindow::rampInBuffer, 1, 
//                      currentITunesSegment.data, 1, 
//                      pkmAudioWindow::rampInLength);
//            // fade out
//            vDSP_vmul(currentITunesSegment.data + segmentSize * frameSize - pkmAudioWindow::rampOutLength, 1, 
//                      pkmAudioWindow::rampOutBuffer, 1, 
//                      currentITunesSegment.data + segmentSize * frameSize - pkmAudioWindow::rampOutLength, 1,
//                      pkmAudioWindow::rampOutLength);
            
#ifdef DO_FILEBASED_SEGMENTS
            pkmEXTAudioFileWriter writer;
            char buf[256];
            sprintf(buf, "%saudiofile_%08d.wav", documentsDirectory.c_str(), currentFile);
            if(!writer.open(ofToDataPath(buf), frameSize, sampleRate))
            {
                printf("[ERROR] Could not write file!\n");
                OF_EXIT_APP(0);
            }
            writer.write(currentITunesSegment.data, 0, segmentSize * frameSize);
            writer.close();
            ofPtr<pkmAudioSegment> audio_segment( new pkmAudioSegment(buf,
                                                                      0,
                                                                      segmentSize * frameSize,
                                                                      currentFile ) );
#else
            ofPtr<pkmAudioSegment> audio_segment( new pkmAudioSegment(currentITunesSegment.data,
                                                                      0,
                                                                      segmentSize * frameSize,
                                                                      currentFile ) );
#endif
            
            audioDatabase->addAudioSegment(audio_segment, currentITunesSegmentFeatures.data, numFeatures);
            audioDatabase->buildIndex();
            
//            logMemUsage();
//            if (audioDatabase->featureDatabase.rows > 5) {
//                pkmAudioFeatureNormalizer::normalizeDatabase(audioDatabase->featureDatabase);
//            }
        }
        
        currentITunesSegment.resetCircularRowCounter();
        currentITunesSegmentFeatures.resetCircularRowCounter();
        
        bDrawNeedsUpdate = true;
    }
}



void app::processInputFrame()
{
    // check for max segment
    bool bMaxSegmentReached = currentSegment.isCircularInsertionFull();
    
    // parse segment
    if(bDetectedOnset || bMaxSegmentReached)
    {
        int segmentSize = bMaxSegmentReached ? currentSegment.rows : currentSegment.current_row;
        
        pkm::Mat croppedFeature(segmentSize, numFeatures, currentSegmentFeatures.data, false);
        pkm::Mat meanFeature = croppedFeature.mean();
        //meanFeature.print();
        if (audioDatabase->bShouldAddSegment(meanFeature.data))
        {
            currentFile++;
            // fade in
//            vDSP_vmul(currentSegment.data, 1,
//                      pkmAudioWindow::rampInBuffer, 1,
//                      currentSegment.data, 1,
//                      pkmAudioWindow::rampInLength);
//            // fade out
//            vDSP_vmul(currentSegment.data + segmentSize * frameSize - pkmAudioWindow::rampOutLength, 1,
//                      pkmAudioWindow::rampOutBuffer, 1,
//                      currentSegment.data + segmentSize * frameSize - pkmAudioWindow::rampOutLength, 1,
//                      pkmAudioWindow::rampOutLength);
            
#ifdef DO_FILEBASED_SEGMENTS
            pkmEXTAudioFileWriter writer;
            char buf[256];
            sprintf(buf, "%saudiofile_%08d.wav", documentsDirectory.c_str(), currentFile);
            if(!writer.open(ofToDataPath(buf), frameSize, sampleRate))
            {
                printf("[ERROR] Could not write file!\n");
                OF_EXIT_APP(0);
            }
            writer.write(currentSegment.data, 0, segmentSize * frameSize);
            writer.close();
            ofPtr<pkmAudioSegment> audio_segment( new pkmAudioSegment(buf,
                                                                      0,
                                                                      segmentSize * frameSize,
                                                                      currentFile ) );
#else
            ofPtr<pkmAudioSegment> audio_segment( new pkmAudioSegment(currentSegment.data,
                                                                      0,
                                                                      segmentSize * frameSize,
                                                                      currentFile ) );
#endif
            
            audioDatabase->addAudioSegment(audio_segment, currentSegmentFeatures.data, numFeatures);
            audioDatabase->buildIndex();
            
            //            logMemUsage();
            //            if (audioDatabase->featureDatabase.rows > 5) {
            //                pkmAudioFeatureNormalizer::normalizeDatabase(audioDatabase->featureDatabase);
            //            }
        }
        
        currentSegment.resetCircularRowCounter();
        currentSegmentFeatures.resetCircularRowCounter();
        
        bDrawNeedsUpdate = true;
    }
}


//--------------------------------------------------------------
void app::audioReceived(float * buf, int size,
                        int ch)
{
    if (!bOutOfMemory && bProcessingSong)
    {
        if(!itunesStream.getNextBuffer(itunes_frame))
            bProcessingSong = false;
        
//        for (int i = 0; i < size * ch; i++)
//        {
//            itunes_frame[i] = compressorInput.compressor(itunes_frame[i], 1.0, 1.0, 0.1, 0.4);
//        }

        // get audio features
        audioFeature->compute36DimAudioFeaturesF(itunes_frame, foreground_features);
        
        // check for onset
        bDetectedOnset = spectralFlux->detectOnset(audioFeature->getMagnitudes(), audioFeature->getMagnitudesLength());
        
        if(bDetectedOnset)
            segmentationCounter = 0;
        
        if (bLearning)
        {
            processITunesInputFrame();
        }
        else
        {
            currentITunesSegment.resetCircularRowCounter();
            currentITunesSegmentFeatures.resetCircularRowCounter();
        }
        // ring buffer for current segment
        currentITunesSegment.insertRowCircularly(itunes_frame);
        
        // ring buffer for audio features
        currentITunesSegmentFeatures.insertRowCircularly(foreground_features);
    }
    else
    {
        cblas_scopy(size, buf, 1, current_frame, 1);
        
//        for (int i = 0; i < size * ch; i++)
//        {
//            current_frame[i] = compressorInput.compressor(current_frame[i], 1.0, 1.0, 0.1, 0.4);
//        }
        
        // get audio features
        audioFeature->compute36DimAudioFeaturesF(buf, foreground_features);
        
        // check for onset
        bDetectedOnset = spectralFlux->detectOnset(audioFeature->getMagnitudes(), audioFeature->getMagnitudesLength());
        
        if(bDetectedOnset)
            segmentationCounter = 0;
        
        if (bLearning) 
        {  
            processInputFrame();  
        }
        else
        {
            currentSegment.resetCircularRowCounter();
            currentSegmentFeatures.resetCircularRowCounter();
        }
        // ring buffer for current segment
        currentSegment.insertRowCircularly(buf);
        
        // ring buffer for audio features
        currentSegmentFeatures.insertRowCircularly(foreground_features);
    }
}

template <class T>
inline bool within(T xt, T yt, 
				   T x, T y, T w, T h)
{
	return xt > x && xt < (x+w) && yt > y && yt < (y+h);
}


#ifdef TARGET_OF_IPHONE
//--------------------------------------------------------------
void app::touchDown(ofTouchEventArgs &touch)
{	
    if(!bConvertingSong && !bWaitingForUserToPickSong && !bOutOfMemory)
    {
		if(touch.y > slider0_y-20 && touch.y < slider0_y+20)
		{
			bMovingSlider0 = true;
            bMovingSlider1 = false;
            bMovingSlider2 = false;
		}
		else if(touch.y > slider1_y-20 && touch.y < slider1_y+20)
		{
			bMovingSlider0 = false;
            bMovingSlider1 = true;
            bMovingSlider2 = false;
		}
		else if(touch.y > slider2_y-20 && touch.y < slider2_y+20)
		{
			bMovingSlider0 = false;
            bMovingSlider1 = false;
            bMovingSlider2 = true;
		}
	}
}

//--------------------------------------------------------------
void app::touchMoved(ofTouchEventArgs &touch){
	if(!bConvertingSong && !bWaitingForUserToPickSong && !bOutOfMemory)
    {
		if(bMovingSlider0)
		{
			slider0_position = MIN(1.0f, MAX(0.0f, (touch.x - slider0_x) / (float)slider_width));
            bDrawNeedsUpdate = true;
            bMovingSlider0 = true;
            bMovingSlider1 = false;
            bMovingSlider2 = false;
		}
		else if(bMovingSlider1)
		{
			slider1_position = MIN(1.0, MAX(0.0, (touch.x - slider1_x) / (float)slider_width));
//			spectralFlux->setOnsetThreshold((1.0f-slider1_position)*3.5f + 0.01f);
            spectralFlux->setMinSegmentLength(sampleRate / (float)frameSize * (float)slider1_position);  // half second
            bDrawNeedsUpdate = true;
            bMovingSlider0 = false;
            bMovingSlider1 = true;
            bMovingSlider2 = false;
		}
		else if(bMovingSlider2)
		{
			slider2_position = MIN(1.0, MAX(0.0, (touch.x - slider2_x) / (float)slider_width));
			audioDatabase->setK(round(slider2_position*maxVoices));
            bDrawNeedsUpdate = true;
            bMovingSlider0 = false;
            bMovingSlider1 = false;
            bMovingSlider2 = true;
		}
	}
    
    if(bDrawNeedsUpdate)
        ofSetFrameRate(30);
}

//--------------------------------------------------------------
void app::touchUp(ofTouchEventArgs &touch)
{
	if(!bConvertingSong && !bWaitingForUserToPickSong && !bOutOfMemory)
    {
		//printf("Checking buttons\n");
        if (within<int>(touch.x, touch.y, button1_x, button1_y, button_width, button_height)) {
            //printf("Button 1 pressed\n");
            audioDatabase->resetDatabase();
            bDrawNeedsUpdate = true;
            currentFile = 0;
        }
        else if(within<int>(touch.x, touch.y, button2_x, button2_y, button_width, button_height)) {
            //printf("Button 2 pressed\n");
            if(bProcessingSong)
            {
                bProcessingSong = false;
                bDrawNeedsUpdate = true;
            }
            else
            {
                itunesStream.pickSong();
                bWaitingForUserToPickSong = true;
            }
        }
        else if(within<int>(touch.x, touch.y, button3_x, button3_y, button_width, button_height)) {
            //printf("Button 3 pressed\n");
            bLearning = !bLearning;
            bDrawNeedsUpdate = true;
        }
		else if(bMovingSlider0)
		{
			slider0_position = MIN(1.0f, MAX(0.0f, (touch.x - slider0_x) / (float)slider_width));
            bDrawNeedsUpdate = true;
		}
		else if(bMovingSlider1)
		{
			slider1_position = MIN(1.0, MAX(0.0, (touch.x - slider1_x) / (float)slider_width));
//            spectralFlux->setOnsetThreshold((1.0f-slider1_position)*3.5f + 0.01f);
            spectralFlux->setMinSegmentLength(sampleRate / (float)frameSize * (float)slider1_position);  // half second
            bDrawNeedsUpdate = true;
		}
		else if(bMovingSlider2)
		{
			slider2_position = MIN(1.0, MAX(0.0, (touch.x - slider2_x) / (float)slider_width));
			audioDatabase->setK(round(slider2_position*maxVoices));
            bDrawNeedsUpdate = true;
		}
		//else if(within<int>(touch.x, touch.y, checkbox1_x, checkbox1_y, checkbox_size, checkbox_size))
		//{
		//	checkbox1 = !checkbox1;
		//	bSyncopated = !bSyncopated;
		//}
    }
    
    bMovingSlider0 = false;
    bMovingSlider1 = false;
    bMovingSlider2 = false;
    
    if(bDrawNeedsUpdate)
        ofSetFrameRate(30);
}

//--------------------------------------------------------------
void app::touchDoubleTap(ofTouchEventArgs &touch)
{
	
}

void app::touchCancelled(ofTouchEventArgs &touch)
{
	
}

void app::gotMemoryWarning()
{
    bOutOfMemory = true;
    bDrawNeedsUpdate = true;
    bLearning = false;
}
#else

void app::mousePressed(int x, int y, int button)
{	
	printf("mouse pressed\n");
    if(!bConvertingSong && !bProcessingSong && !bWaitingForUserToPickSong && !bOutOfMemory)
    {
		//printf("Checking buttons\n");
        if (within<int>(x, y, button1_x, button1_y, button_width, button_height)) {
            //printf("Button 1 pressed\n");
            audioDatabase->resetDatabase();
            bDrawNeedsUpdate = true;
            currentFile = 0;
        }
        else if(within<int>(x, y, button2_x, button2_y, button_width, button_height)) {
            //printf("Button 2 pressed\n");   
			string filename;
			if(ofxFileDialogOSX::openFile(filename) == 1)
			{
				printf("Reading %s\n", filename.c_str());
				songReader.open(filename);
				bLoadedSong = true;
			}
        }
        else if(within<int>(x, y, button3_x, button3_y, button_width, button_height)) {
            //printf("Button 3 pressed\n");     
            bLearning = !bLearning;
            bDrawNeedsUpdate = true;
        }
		else if(within<int>(x, y, slider0_x, slider0_y-20, slider_width, 40))
		{
			slider0_position =MIN(0.99f, MAX(0.01f, (x - slider0_x) / (float)slider_width));
            bDrawNeedsUpdate = true;
		}
		else if(within<int>(x, y, slider1_x, slider1_y-20, slider_width, 40))
		{
			slider1_position = (x - slider1_x) / (float)slider_width;
            bDrawNeedsUpdate = true;
//            spectralFlux->setOnsetThreshold((1.0f-slider1_position)*3.5f + 0.01f);
            spectralFlux->setMinSegmentLength(sampleRate / (float)frameSize * (float)slider1_position);  // half second
		}
		else if(within<int>(x, y, slider2_x, slider2_y-20, slider_width, 40))
		{
			slider2_position = (x - slider2_x) / (float)slider_width;
            bDrawNeedsUpdate = true;
			audioDatabase->setK(slider2_position*15);
		}
		//else if(within<int>(x, y, checkbox1_x, checkbox1_y, checkbox_size, checkbox_size))
		//{
		//	checkbox1 = !checkbox1;
		//	bSyncopated = !bSyncopated;
		//}
    }
    
    
    if(bDrawNeedsUpdate)
        ofSetFrameRate(30);
	
}

//--------------------------------------------------------------
void app::mouseDragged(int x, int y, int button){
	
    printf("mouse moved\n");
    if(!bConvertingSong && !bProcessingSong && !bWaitingForUserToPickSong && !bOutOfMemory)
    {
        if(within<int>(x, y, slider0_x, slider0_y-20, slider_width, 40))
        {
            slider0_position =MIN(0.99f, MAX(0.01f, (x - slider0_x) / (float)slider_width));
            bDrawNeedsUpdate = true;
        }
        else if(within<int>(x, y, slider1_x, slider1_y-20, slider_width, 40))
        {
            slider1_position = (x - slider1_x) / (float)slider_width;
            bDrawNeedsUpdate = true;
//            spectralFlux->setOnsetThreshold((1.0f-slider1_position)*3.5f + 0.01f);
            spectralFlux->setMinSegmentLength(sampleRate / (float)frameSize * (float)slider1_position);  // half second
        }
        else if(within<int>(x, y, slider2_x, slider2_y-20, slider_width, 40))
        {
            slider2_position = (x - slider2_x) / (float)slider_width;
            bDrawNeedsUpdate = true;
            audioDatabase->setK(slider2_position*6.0f);
        }
    }
	
    
    if(bDrawNeedsUpdate)
        ofSetFrameRate(30);
}

void app::mouseReleased(int x, int y)
{
	printf("mouse released\n");
    
}

#endif
