SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_AGOP_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	DECLARE @Code BIGINT
	       ,@RegnPrvnCntyCode VARCHAR(3)
	       ,@RegnPrvnCode VARCHAR(3)
	       ,@RegnCode VARCHAR(3)
	       ,@RqtpCode VARCHAR(3)
	       ,@RqttCode VARCHAR(3)
	       ,@MtodCode BIGINT
	       ,@CtgyCode BIGINT
	       ,@CochFileNo BIGINT
	       ,@CbmtCode BIGINT
	       ,@OprtType VARCHAR(3)
	       ,@OprtStat VARCHAR(3)
	       ,@FromDate DATE
	       ,@ToDate DATE
	       ,@NumbMontOffr INT
	       ,@NumbOfAttnMont INT
	       ,@NewCbmtCode BIGINT
	       ,@NewMtodCode BIGINT
	       ,@NewCtgyCode BIGINT
	       ,@AgopDesc NVARCHAR(500);
   
   SELECT @Code = @X.query('//Aggregation_Operation').value('(Aggregation_Operation/@code)[1]'    , 'BIGINT')
         ,@RegnPrvnCntyCode = @X.query('//Aggregation_Operation').value('(Aggregation_Operation/@regnprvncntycode)[1]'    , 'VARCHAR(3)')
         ,@RegnPrvnCode = @X.query('//Aggregation_Operation').value('(Aggregation_Operation/@regnprvncode)[1]'    , 'VARCHAR(3)')
         ,@RegnCode = @X.query('//Aggregation_Operation').value('(Aggregation_Operation/@regncode)[1]'    , 'VARCHAR(3)')
         ,@RqtpCode = @X.query('//Aggregation_Operation').value('(Aggregation_Operation/@rqtpcode)[1]'    , 'VARCHAR(3)')
         ,@RqttCode = @X.query('//Aggregation_Operation').value('(Aggregation_Operation/@rqttcode)[1]'    , 'VARCHAR(3)')
         ,@MtodCode = @X.query('//Aggregation_Operation').value('(Aggregation_Operation/@mtodcode)[1]'    , 'BIGINT')
         ,@CtgyCode = @X.query('//Aggregation_Operation').value('(Aggregation_Operation/@ctgycode)[1]'    , 'BIGINT')
         ,@CochFileNo = @X.query('//Aggregation_Operation').value('(Aggregation_Operation/@cochfileno)[1]'    , 'BIGINT')
         ,@CbmtCode = @X.query('//Aggregation_Operation').value('(Aggregation_Operation/@cbmtcode)[1]'    , 'BIGINT')
         ,@OprtType = @X.query('//Aggregation_Operation').value('(Aggregation_Operation/@oprttype)[1]'    , 'VARCHAR(3)')
         ,@OprtStat = @X.query('//Aggregation_Operation').value('(Aggregation_Operation/@oprtstat)[1]'    , 'VARCHAR(3)')
         ,@FromDate = @X.query('//Aggregation_Operation').value('(Aggregation_Operation/@fromdate)[1]'    , 'DATE')
         ,@ToDate = @X.query('//Aggregation_Operation').value('(Aggregation_Operation/@todate)[1]'    , 'DATE')
         ,@NumbMontOffr = @X.query('//Aggregation_Operation').value('(Aggregation_Operation/@numbmontoffr)[1]'    , 'INT')
         ,@NumbOfAttnMont = @X.query('//Aggregation_Operation').value('(Aggregation_Operation/@numbofattnmont)[1]'    , 'INT')
         ,@NewCbmtCode = @X.query('//Aggregation_Operation').value('(Aggregation_Operation/@newcbmtcode)[1]'    , 'BIGINT')
         ,@NewMtodCode = @X.query('//Aggregation_Operation').value('(Aggregation_Operation/@newmtodcode)[1]'    , 'BIGINT')
         ,@NewCtgyCode = @X.query('//Aggregation_Operation').value('(Aggregation_Operation/@newctgycode)[1]'    , 'BIGINT')
         ,@AgopDesc = @X.query('//Aggregation_Operation').value('(Aggregation_Operation/@agopdesc)[1]'    , 'NVARCHAR(500)');
   
   -- Check Validate Data
   IF @RegnCode IS NOT NULL AND @RegnPrvnCode IS NULL
   BEGIN
      SELECT @RegnPrvnCode = PRVN_CODE
            ,@RegnPrvnCntyCode = PRVN_CNTY_CODE
        FROM dbo.Region
       WHERE Code = @RegnCode;
   END
   
   IF @CtgyCode = 0
      SELECT @CtgyCode = NULL;
   
   IF @RqttCode IS NULL
      SELECT @RqttCode = '001';
   
   IF (@CtgyCode IS NOT NULL OR @CtgyCode != 0) AND (@MtodCode IS NULL OR @MtodCode = 0)
   BEGIN
      SELECT @MtodCode = MTOD_CODE
        FROM dbo.Category_Belt
       WHERE Code = @CtgyCode;
   END;
   
   IF (@NewCtgyCode IS NOT NULL OR @NewCtgyCode != 0) AND (@NewMtodCode IS NULL OR @NewMtodCode = 0)
   BEGIN
      SELECT @NewMtodCode = MTOD_CODE
        FROM dbo.Category_Belt
       WHERE Code = @NewCtgyCode;
   END;
   
   IF @MtodCode = 0
      SELECT @MtodCode = NULL;
   
   IF @NewMtodCode = 0
      SELECT @NewMtodCode = NULL;

   
   IF @CbmtCode IS NOT NULL OR @CbmtCode != 0
   BEGIN
      SELECT @CochFileNo = cm.COCH_FILE_NO
            ,@MtodCode = cm.MTOD_CODE
            ,@RegnCode = C.REGN_CODE
            ,@RegnPrvnCode = C.REGN_PRVN_CODE
            ,@RegnPrvnCntyCode = C.REGN_PRVN_CNTY_CODE
        FROM dbo.Club_Method cm, dbo.Club c
       WHERE cm.CODE = @CbmtCode
         AND C.CODE = Cm.CLUB_CODE;
   END
   
   IF @CbmtCode = 0
      SELECT @CbmtCode = NULL;
   
   IF @NewCbmtCode = 0
      SELECT @NewCbmtCode = NULL;
   
   IF @CochFileNo = 0
      SELECT @CochFileNo = NULL;
   
   IF @FromDate = '1900-01-01'
      SELECT @FromDate = GETDATE();
   
   IF @TODate = '1900-01-01'
      SELECT @ToDate = GETDATE();
   
   
   -- End Check Validate Data
   
   -- Check Security Account
   
   -- End Check Security Account
   IF @Code = 0
      SET @Code = Dbo.GNRT_NVID_U();
   
   IF NOT EXISTS(
      SELECT * 
        FROM dbo.Aggregation_Operation
       WHERE CODE = @Code
   )
   BEGIN   
      INSERT INTO dbo.Aggregation_Operation
              ( CODE ,
                REGN_PRVN_CNTY_CODE ,
                REGN_PRVN_CODE ,
                REGN_CODE ,
                RQTP_CODE ,
                RQTT_CODE ,
                --REGL_YEAR ,
                --REGL_CODE ,
                MTOD_CODE ,
                CTGY_CODE ,
                COCH_FILE_NO ,
                CBMT_CODE ,
                OPRT_TYPE ,
                OPRT_STAT ,
                FROM_DATE ,
                TO_DATE ,
                NUMB_MONT_OFFR,
                NUMB_OF_ATTN_MONT,
                NEW_CBMT_CODE,
                NEW_MTOD_CODE,
                NEW_CTGY_CODE,
                AGOP_DESC
              )
      VALUES  ( @Code , -- CODE - bigint
                @RegnPrvnCntyCode , -- REGN_PRVN_CNTY_CODE - varchar(3)
                @RegnPrvnCode , -- REGN_PRVN_CODE - varchar(3)
                @RegnCode , -- REGN_CODE - varchar(3)
                @RqtpCode , -- RQTP_CODE - varchar(3)
                @RqttCode , -- RQTT_CODE - varchar(3)
                --0 , -- REGL_YEAR - smallint
                --0 , -- REGL_CODE - int
                @MtodCode , -- MTOD_CODE - bigint
                @CtgyCode , -- CTGY_CODE - bigint
                @CochFileNo , -- COCH_FILE_NO - bigint
                @CbmtCode , -- CBMT_CODE - bigint
                @OprtType , -- OPRT_TYPE - varchar(3)
                @OprtStat , -- OPRT_STAT - varchar(3)
                @FromDate , -- FROM_DATE - date
                @ToDate , -- TO_DATE - date
                @NumbMontOffr,  -- NUMB_MONT_OFFR - int
                @NumbOfAttnMont,
                @NewCbmtCode, -- NEW_CBMT_CODE - bigint
                @NewMtodCode,
                @NewCtgyCode,
                @AgopDesc
              );
   END
   ELSE
   BEGIN
      UPDATE dbo.Aggregation_Operation
         SET REGN_PRVN_CNTY_CODE = @RegnPrvnCntyCode
            ,REGN_PRVN_CODE = @RegnPrvnCode
            ,REGN_CODE = @RegnCode
            ,RQTP_CODE = @RqtpCode
            ,RQTT_CODE = @RqttCode
            ,MTOD_CODE = CASE @MtodCode WHEN 0 THEN NULL ELSE @MtodCode END
            ,CTGY_CODE = CASE @CtgyCode WHEN 0 THEN NULL ELSE @CtgyCode END
            ,COCH_FILE_NO = CASE @CochFileNo WHEN 0 THEN NULL ELSE @CochFileNo END
            ,CBMT_CODE = CASE @CbmtCode WHEN 0 THEN NULL ELSE @CbmtCode END
            ,OPRT_TYPE = @OprtType
            ,OPRT_STAT = @OprtStat
            ,FROM_DATE = @FromDate
            ,TO_DATE = @ToDate
            ,NUMB_MONT_OFFR = @NumbMontOffr
            ,NUMB_OF_ATTN_MONT = @NumbOfAttnMont
            ,NEW_CBMT_CODE = CASE @NewCbmtCode WHEN 0 THEN NULL ELSE @NewCbmtCode END
            ,NEW_MTOD_CODE = CASE @NewMtodCode WHEN 0 THEN NULL ELSE @NewMtodCode END
            ,NEW_CTGY_CODE = CASE @NewCtgyCode WHEN 0 THEN NULL ELSE @NewCtgyCode END
            ,AGOP_DESC = @AgopDesc
      WHERE Code = @Code;
   END
END
GO
