/*
 * HMC.cpp - Interface a Honeywell HMC5843 magnetometer to an AVR via i2c
 * Version 0.2 - http://eclecti.cc
 * Copyright (c) 2009 Nirav Patel, modified/extended by E.J.Muller
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE FOUNDATION OR CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * Code based in part on information from the following:
 * http://www.sparkfun.com/datasheets/Sensors/Magneto/HMC5843-v11.c
 * http://www.atmel.com/dyn/resources/prod_documents/doc2545.pdf
 */
 
#include "HMC.h"
#include <util\delay.h>
#define HMC_POS_BIAS 1
#define HMC_NEG_BIAS 2

/* PUBLIC METHODS */

HMC5843::HMC5843()
{ x_scale=1;
  y_scale=1;
  z_scale=1;
}

// note that you need to wait at least 5ms after power on to initialize
void HMC5843::init(bool setmode)
{
  PORTC = 0b00110000; // Use the internal pull up resistors
  // Choose 100KHz for the bus.  Formula from 21.5.2 in ATmega168 datasheet.
  TWSR &= ~((1<<TWPS1)&(1<<TWPS0));
  TWBR = (unsigned char)(F_CPU/200000l-8);
  //
  if (setmode) setMode(0);	
}

void HMC5843::setMode(unsigned char mode)
{ if (mode>2) return;
  sendStart();
  sendByte(0x3C); 
  sendByte(0x02);
  sendByte(mode);
  sendStop();
  _delay_ms(100);
}

void HMC5843::calibrate(unsigned char gain)
{ x_scale=1; // get actual values
  y_scale=1;
  z_scale=1;
  writeReg(0,0x010+HMC_POS_BIAS); // Reg A DOR=0x010 + MS1,MS0 set to pos bias
  setGain(gain);
  float x,y,z,mx=0,my=0,mz=0,t=10;
  for (int i=0;i<(int)t;i++)
  { setMode(1);
    getValues(&x,&y,&z);
    if (x>mx) mx=x;
    if (y>my) my=y;
    if (z>mz) mz=z;
  }
  float max=0;
  if (mx>max) max=mx;
  if (my>max) max=my;
  if (mz>max) max=mz;
  x_max=mx;
  y_max=my;
  z_max=mz;
  x_scale=max/mx; // calc scales
  y_scale=max/my;
  z_scale=max/mz;
  writeReg(0,0x010); // set RegA/DOR back to default
}

// set data output rate
void HMC5843::setDOR(unsigned char DOR) // 0-6, 4 default, normal operation assumed
{ if (DOR>6) return;
  writeReg(0,DOR<<2);
}

void HMC5843::setGain(unsigned char gain) // 0-7, 1 default
{ if (gain>7) return;
  writeReg(1,gain<<5);
}

void HMC5843::writeReg(unsigned char reg,unsigned char val)
{ sendStart();
  sendByte(0x3C);
  sendByte(reg);
  sendByte(val);
  sendStop();
}

void HMC5843::getValues(int *x,int *y,int *z)
{ float fx,fy,fz;
  getValues(&fx,&fy,&fz);
  *x=(float)fx+0.5;
  *y=(float)fy+0.5;
  *z=(float)fz+0.5;
}

void HMC5843::getValues(float *x,float *y,float *z)
{ int xr,yr,zr;
  sendStart();
  sendByte(0x3D);
  // read out the 3 values, 2 bytes each.
  xr = receiveByte();
  xr = (xr<<8)+receiveByte();
  *x=(float)xr/x_scale;
  yr = receiveByte();
  yr = (yr<<8)+receiveByte();
  *y =(float)yr/y_scale;
  zr = receiveByte();
  zr = (zr<<8)+receiveByte();
  *z =(float)zr/z_scale;
  // wrap back around for the next set of reads and close
  sendByte(0x3D);
  sendStop();
}

/* PRIVATE METHODS */

// start i2c as the master
void HMC5843::sendStart(void)
{
  TWCR = (1<<TWINT)|(1<<TWSTA)|(1<<TWEN);
}

// close i2c
void HMC5843::sendStop(void)
{
  waitForReady();
  TWCR = (1<<TWINT)|(1<<TWEN)|(1<<TWSTO);
}

// send a byte when the channel is ready
void HMC5843::sendByte(unsigned char data)
{
  waitForReady();
	TWDR = data;
	TWCR = (1<<TWINT)|(1<<TWEN);
}

// ask for a byte, wait for it arrive, and return it
unsigned char HMC5843::receiveByte(void)
{
  waitForReady();
  TWCR = ((TWCR&0x0F)|(1<<TWINT)|(1<<TWEA));
	waitForReady();
	return(TWDR);
}

// get status register. the bits 0 and 1 are zeroed in init. see datasheet
unsigned char HMC5843::readStatus()
{
  waitForReady();
  return(TWSR);
}

// wait for TWINT to be set before touching the other registers.
void HMC5843::waitForReady(void)
{
  // timeout after some time to avoid locking up if something goes wrong
  int timeout = 200;
  while ((!(TWCR & (1<<TWINT))) && (timeout--));
}

// Set the default object
HMC5843 HMC = HMC5843();
