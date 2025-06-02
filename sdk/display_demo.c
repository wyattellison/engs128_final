/************************************************************************/
/*																		*/
/*	display_demo.c	--	ZYBO Display demonstration 						*/
/*																		*/
/************************************************************************/
/*	Author: Sam Bobrowicz												*/
/*	Copyright 2016, Digilent Inc.										*/
/************************************************************************/
/*  Module Description: 												*/
/*																		*/
/*		This file contains code for running a demonstration of the		*/
/*		HDMI output capabilities on the ZYBO. It is a good	            */
/*		example of how to properly use the display_ctrl drivers.	    */
/*																		*/
/************************************************************************/
/*  Revision History:													*/
/* 																		*/
/*		2/5/2016(SamB): Created											*/
/*																		*/
/************************************************************************/

/* ------------------------------------------------------------ */
/*				Include File Definitions						*/
/* ------------------------------------------------------------ */

#include "display_demo.h"
#include "display_ctrl/display_ctrl.h"
#include "intc/intc.h"
#include <stdio.h>
#include "xuartps.h"
#include "math.h"
#include <ctype.h>
#include <stdlib.h>
#include "xil_types.h"
#include "xil_cache.h"
#include "timer_ps/timer_ps.h"
#include "xparameters.h"

#include "xil_printf.h"
#include "iic/iic.h"
#include "audio/audio.h"

#include "xil_exception.h"
#include "xdebug.h"
#include "xiic.h"
#include "xtime_l.h"
#include "xscugic.h"
#include "sleep.h"
#include "xil_cache.h"

#include "xil_cache.h"
/*
 * XPAR redefines
 */

#define DYNCLK_BASEADDR 		XPAR_AXI_DYNCLK_0_S_AXI_LITE_BASEADDR
#define HDMI_OUT_VTC_ID 		XPAR_V_TC_0_DEVICE_ID //was XPAR_V_TC_OUT_DEVICE_ID
#define SCU_TIMER_ID 			XPAR_SCUTIMER_DEVICE_ID
#define UART_BASEADDR 			XPAR_PS7_UART_1_BASEADDR

/* ------------------------------------------------------------ */
/*				Global Variables								*/
/* ------------------------------------------------------------ */
DisplayCtrl dispCtrl;
INTC intc;
char fRefresh; //flag used to trigger a refresh of the Menu on video detect

/*
 * Framebuffers for video data
 */
u8 frameBuf[DISPLAY_NUM_FRAMES][DEMO_MAX_FRAME] __attribute__((aligned(0x20)));
u8 *pFrames[DISPLAY_NUM_FRAMES]; //array of pointers to the frame buffers
/* ------------------------------------------------------------ */
/*				Procedure Definitions							*/
/* ------------------------------------------------------------ */


// Device instances
static XIic sIic;
static XScuGic sIntc;

 // Interrupt vector table
 const ivt_t ivt[] = {
 	//IIC
 	{XPAR_FABRIC_AXI_IIC_0_IIC2INTC_IRPT_INTR, (Xil_ExceptionHandler)XIic_InterruptHandler, &sIic}
 };

int main(void)
{
	DemoInitialize();

	//DemoRun();

	return 0;
}


void DemoInitialize()
{
	int Status;

	//Initialize the interrupt controller
	Status = fnInitInterruptController(&sIntc);
	if(Status != XST_SUCCESS) {
		xil_printf("Error initializing interrupts");
		return XST_FAILURE;
	}

	// Initialize IIC controller
	Status = fnInitIic(&sIic);
	if(Status != XST_SUCCESS) {
		xil_printf("Error initializing I2C controller");
		return XST_FAILURE;
	}


	// Initialize Audio Codec I2S
	Status = fnInitAudio();
	if(Status != XST_SUCCESS) {
		xil_printf("Audio initializing ERROR");
		return XST_FAILURE;
	}

	{
		XTime  tStart, tEnd;

		XTime_GetTime(&tStart);
		do {
			XTime_GetTime(&tEnd);
		}
		while((tEnd-tStart)/(COUNTS_PER_SECOND/10) < 20);
	}
	//Initialize Audio I2S
	Status = fnInitAudio();
	if(Status != XST_SUCCESS) {
		xil_printf("Audio initializing ERROR");
		return XST_FAILURE;
	}

	fnSetLineInput();
	//fnSetHpOutput();	// NOTE: do not set HP output

	// Enable all interrupts in our interrupt vector table
	// Make sure all driver instances using interrupts are initialized first
	fnEnableInterrupts(&sIntc, &ivt[0], sizeof(ivt)/sizeof(ivt[0]));


    print("Audio codec initialized.\n\r");
    print("Successfully ran configuration sequence.");



	int i;
	/*
	 * Initialize an array of pointers to the 3 frame buffers
	 */
	for (i = 0; i < DISPLAY_NUM_FRAMES; i++)
	{
		pFrames[i] = frameBuf[i];
	}

	/*
	 * Initialize a timer used for a simple delay
	 */
	TimerInitialize(SCU_TIMER_ID);

	/*
	 * Initialize the Display controller and start it
	 */
	Status = DisplayInitialize(&dispCtrl, HDMI_OUT_VTC_ID, DYNCLK_BASEADDR, pFrames, DEMO_STRIDE);
	if (Status != XST_SUCCESS)
	{
		xil_printf("Display Ctrl initialization failed during demo initialization%d\r\n", Status);
		return;
	}
	Status = DisplayStart(&dispCtrl);
	if (Status != XST_SUCCESS)
	{
		xil_printf("Couldn't start display during demo initialization%d\r\n", Status);
		return;
	}

	//DemoPrintTest(dispCtrl.framePtr[dispCtrl.curFrame], dispCtrl.vMode.width, dispCtrl.vMode.height, dispCtrl.stride, DEMO_PATTERN_1);

	return;
}

