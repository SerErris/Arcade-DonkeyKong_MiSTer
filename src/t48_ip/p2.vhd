-------------------------------------------------------------------------------
--
-- The Port 2 unit.
-- Implements the Port 2 logic.
--
-- $Id: p2.vhd,v 1.6 2004/07/11 16:51:33 arniml Exp $
--
-- Copyright (c) 2004, Arnim Laeuger (arniml@opencores.org)
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- Please report bugs to the author, but before you do so, please
-- make sure that this is not a derivative work and that
-- you have the latest version of this file.
--
-- The latest version of this file can be found at:
--      http://www.opencores.org/cvsweb.shtml/t48/
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.t48_pack.word_t;
use work.t48_pack.nibble_t;

entity p2 is

  port (
    -- Global Interface -------------------------------------------------------
    clk_i        : in  std_logic;
    res_i        : in  std_logic;
    en_clk_i     : in  boolean;
    -- T48 Bus Interface ------------------------------------------------------
    data_i       : in  word_t;
    data_o       : out word_t;
    write_p2_i   : in  boolean;
    write_exp_i  : in  boolean;
    read_p2_i    : in  boolean;
    read_reg_i   : in  boolean;
    read_exp_i   : in  boolean;
    -- Port 2 Interface -------------------------------------------------------
    output_pch_i : in  boolean;
    output_exp_i : in  boolean;
    pch_i        : in  nibble_t;
    p2_i         : in  word_t;
    p2_o         : out word_t;
    p2_low_imp_o : out std_logic
  );

end p2;


use work.t48_pack.clk_active_c;
use work.t48_pack.res_active_c;
use work.t48_pack.bus_idle_level_c;

architecture rtl of p2 is

  -- the port output register
  signal p2_q   : word_t;

  -- the low impedance marker
  signal low_imp_q : std_logic;

  -- the expander register
  signal exp_q  : nibble_t;

begin

  -----------------------------------------------------------------------------
  -- Process p2_regs
  --
  -- Purpose:
  --   Implements the port output and expander registers.
  --
  p2_regs: process (res_i, clk_i)
  begin
    if res_i = res_active_c then
      p2_q          <= (others => '1');
      low_imp_q     <= '0';
      exp_q         <= (others => '0');

    elsif clk_i'event and clk_i = clk_active_c then
      if en_clk_i then

        if write_p2_i then
          p2_q      <= data_i;
          low_imp_q <= '1';
        else
          low_imp_q <= '0';
        end if;

        if write_exp_i then
          exp_q     <= data_i(exp_q'range);
        end if;

      end if;

    end if;

  end process p2_regs;
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Process p2_port
  --
  -- Purpose:
  --   Generates the output byte vector for Port 2.
  --
  p2_port: process (p2_q,
                    exp_q,
                    output_exp_i,
                    pch_i,
                    output_pch_i)
  begin
    p2_o                   <= p2_q;

    if output_exp_i then
      p2_o(nibble_t'range) <= exp_q;
    end if;

    if output_pch_i then
      p2_o(nibble_t'range) <= pch_i;
    end if;

  end process p2_port;
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Process p2_data
  --
  -- Purpose:
  --   Generates the T48 bus data.
  --
  p2_data: process (read_p2_i,
                    p2_i,
                    read_reg_i,
                    p2_q,
                    read_exp_i)
  begin
    data_o   <= (others => bus_idle_level_c);

    if read_p2_i then
      if read_reg_i then
        data_o <= p2_q;
      elsif read_exp_i then
        data_o <= "0000" & p2_i(nibble_t'range);
      else
        data_o <= p2_i;
      end if;
    end if;

  end process p2_data;
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Output Mapping.
  -----------------------------------------------------------------------------
  p2_low_imp_o <= low_imp_q;

end rtl;


-------------------------------------------------------------------------------
-- File History:
--
-- $Log: p2.vhd,v $
-- Revision 1.6  2004/07/11 16:51:33  arniml
-- cleanup copyright notice
--
-- Revision 1.5  2004/05/17 13:52:46  arniml
-- Fix bug "ANL and ORL to P1/P2 read port status instead of port output register"
--
-- Revision 1.4  2004/04/24 23:44:25  arniml
-- move from std_logic_arith to numeric_std
--
-- Revision 1.3  2004/03/29 19:39:58  arniml
-- rename pX_limp to pX_low_imp
--
-- Revision 1.2  2004/03/28 13:11:43  arniml
-- rework Port 2 expander handling
--
-- Revision 1.1  2004/03/23 21:31:53  arniml
-- initial check-in
--
-------------------------------------------------------------------------------
