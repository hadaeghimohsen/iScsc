SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[RELD_CEXC_F]	
   @X XML
AS
BEGIN
	   DECLARE C$CochCG$AUPD_BSEX CURSOR FOR
      SELECT F.File_No, P.Coch_Deg
        FROM Fighter F, Fighter_Public P
       WHERE F.File_No = P.Figh_File_No
         AND F.Fgpb_Rwno_Dnrm = P.Rwno
         AND P.Rect_Code = '004'
         AND F.Fgpb_Type_Dnrm IN ('003')
         AND F.Conf_Stat = '002';
   
   DECLARE C$BsexCG$AUPD_BSEX CURSOR FOR
      SELECT Epit_Code, Rqtt_Code, Coch_Deg, Prct_Valu,
             RQTP_CODE, MTOD_CODE, CTGY_CODE, CALC_TYPE,
             PYMT_STAT, CALC_EXPN_TYPE
        FROM Base_Calculate_Expense
       WHERE Stat = '002';
   
   DECLARE @FileNo BIGINT
          ,@CochDeg VARCHAR(3)
          ,@BCochDeg VARCHAR(3)
          ,@EpitCode BIGINT
          ,@RqttCode VARCHAR(3)
          ,@PrctValu FLOAT
          ,@RqtpCode VARCHAR(3)
          ,@MtodCode BIGINT
          ,@CtgyCode BIGINT
          ,@CalcType VARCHAR(3)
          ,@PymtStat VARCHAR(3)
          ,@CalcExpnType VARCHAR(3);
   
   OPEN C$CochCG$AUPD_BSEX;
   FETCHC$CochCG$AUPD_BSEX:
   FETCH NEXT FROM C$CochCG$AUPD_BSEX INTO @FileNo, @CochDeg;
   
   IF @@FETCH_STATUS <> 0
      GOTO CLOSEC$CochCG$AUPD_BSEX;
      
      OPEN C$BsexCG$AUPD_BSEX;
      FETCHC$BsexCG$AUPD_BSEX:
      FETCH NEXT FROM C$BsexCG$AUPD_BSEX INTO @EpitCode, @RqttCode, @BCochDeg, @PrctValu, @RqtpCode, @MtodCode, @CtgyCode, @CalcType, @PymtStat, @CalcExpnType;
      
      IF @@FETCH_STATUS <> 0
         GOTO CLOSEC$BsexCG$AUPD_BSEX;     
      
      IF @CochDeg = @BCochDeg AND NOT EXISTS(SELECT * FROM Calculate_Expense_Coach WHERE COCH_FILE_NO = @FileNo AND EPIT_CODE = @EpitCode AND RQTT_CODE = @RqttCode AND RQTP_CODE = @RqtpCode AND MTOD_CODE = @MtodCode AND CTGY_CODE = @CtgyCode AND CALC_TYPE = @CalcType AND PYMT_STAT = @PymtStat AND CALC_EXPN_TYPE = @CalcExpnType)
      BEGIN
         INSERT INTO Calculate_Expense_Coach (COCH_FILE_NO, EPIT_CODE, RQTT_CODE, PRCT_VALU, COCH_DEG, RQTP_CODE, MTOD_CODE, CTGY_CODE, CALC_TYPE, PYMT_STAT, CALC_EXPN_TYPE)
         VALUES (@FileNo, @EpitCode, @RqttCode, @PrctValu, @CochDeg, @RqtpCode, @MtodCode, @CtgyCode, @CalcType, @PymtStat, @CalcExpnType);
      END
         
      GOTO FETCHC$BsexCG$AUPD_BSEX;
      CLOSEC$BsexCG$AUPD_BSEX:
      CLOSE C$BsexCG$AUPD_BSEX;      
   
   GOTO FETCHC$CochCG$AUPD_BSEX;
   CLOSEC$CochCG$AUPD_BSEX:
   CLOSE C$CochCG$AUPD_BSEX;
   DEALLOCATE C$CochCG$AUPD_BSEX;
   DEALLOCATE C$BsexCG$AUPD_BSEX;
END
GO
