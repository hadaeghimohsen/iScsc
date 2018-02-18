SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DUP_CSCC_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	DECLARE @SorcCochFileNo BIGINT
	       ,@TrgtCochFileNo BIGINT
	       ,@TrgtClubCode BIGINT;
   
   SELECT @SorcCochFileNo = @X.query('/Duplicate').value('(Duplicate/@sorccochfileno)[1]', 'BIGINT')
         ,@TrgtCochFileNo = @X.query('/Duplicate').value('(Duplicate/@trgtcochfileno)[1]', 'BIGINT')
         ,@TrgtClubCode = @X.query('/Duplicate').value('(Duplicate/@trgtclubcode)[1]', 'BIGINT');
   
   IF @SorcCochFileNo = 0 AND @SorcCochFileNo IS NULL
      RETURN;
   
   IF @TrgtCochFileNo = 0 AND @TrgtCochFileNo IS NULL
      RETURN;
   
   IF @TrgtClubCode = 0 AND @TrgtClubCode IS NULL
      RETURN;
   
   DECLARE C$Cbmt CURSOR FOR
      SELECT MTOD_CODE, 
             DAY_TYPE,
             STRT_TIME,
             END_TIME,
             MTOD_STAT,
             SEX_TYPE,
             CBMT_DESC,
             DFLT_STAT,
             CPCT_NUMB,
             CPCT_STAT,
             CBMT_TIME,
             CBMT_TIME_STAT,
             CLAS_TIME
        FROM dbo.Club_Method cms
       WHERE cms.COCH_FILE_NO = @SorcCochFileNo
         AND NOT EXISTS(
            SELECT *
              FROM dbo.Club_Method cmt
             WHERE cmt.COCH_FILE_NO = @TrgtCochFileNo
               AND cmt.MTOD_CODE = cms.MTOD_CODE
               AND cmt.STRT_TIME = cms.STRT_TIME
               AND cmt.END_TIME = cms.END_TIME
               AND cmt.SEX_TYPE = cms.SEX_TYPE
               AND cmt.DAY_TYPE = cms.DAY_TYPE
               AND cmt.CLUB_CODE = @TrgtClubCode
         );
   
   DECLARE @MtodCode BIGINT
          ,@DayType VARCHAR(3)
          ,@StrtTime TIME(0)
          ,@EndTime TIME(0)
          ,@MtodStat VARCHAR(3)
          ,@SexType VARCHAR(3)
          ,@CbmtDesc NVARCHAR(250)
          ,@DfltStat VARCHAR(3)
          ,@CpctNumb INT
          ,@CpctStat VARCHAR(3)
          ,@CbmtTime INT 
          ,@CbmtTimeStat VARCHAR(3)
          ,@ClasTime INT;
   
   OPEN [C$Cbmt];
   L$Loop:
   FETCH [C$Cbmt] INTO 
      @MtodCode, 
      @DayType, 
      @StrtTime, 
      @EndTime, 
      @MtodStat, 
      @SexType, 
      @CbmtDesc,
      @DfltStat,
      @CpctNumb,
      @CpctStat,
      @CbmtTime,
      @CbmtTimeStat,
      @ClasTime;
   
   IF @@FETCH_STATUS <> 0
      GOTO L$EndLoop;
   
   INSERT INTO dbo.Club_Method
   ( CLUB_CODE ,
     MTOD_CODE ,
     COCH_FILE_NO ,
     CODE ,
     DAY_TYPE ,
     STRT_TIME ,
     END_TIME ,
     MTOD_STAT ,
     SEX_TYPE ,
     CBMT_DESC ,
     DFLT_STAT ,
     CPCT_NUMB ,
     CPCT_STAT ,
     CBMT_TIME ,
     CBMT_TIME_STAT ,
     CLAS_TIME )
   VALUES
   ( @TrgtClubCode, 
     @MtodCode, 
     @TrgtCochFileNo,
     0,
     @DayType, 
     @StrtTime, 
     @EndTime, 
     @MtodStat, 
     @SexType, 
     @CbmtDesc,
     @DfltStat,
     @CpctNumb,
     @CpctStat,
     @CbmtTime,
     @CbmtTimeStat,
     @ClasTime );
      
   
   GOTO L$Loop;
   L$EndLoop:
   CLOSE [C$Cbmt];
   DEALLOCATE [C$Cbmt];   
END
GO
