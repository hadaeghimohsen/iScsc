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
	       ,@AgopDesc NVARCHAR(500)
	       ,@UnitBlokCndoCode VARCHAR(3)
	       ,@UnitBlokCode VARCHAR(3)
	       ,@UnitCode VARCHAR(3)
	       ,@SuntBuntDeptOrgnCode VARCHAR(2)
	       ,@SuntBuntDeptCode VARCHAR(2)
	       ,@SuntBuntCode VARCHAR(2)
	       ,@SuntCode VARCHAR(4)
	       ,@LettNo VARCHAR(15)
	       ,@LettDate DATETIME
	       ,@LettOwnr NVARCHAR(250)
	       ,@ExpnAmnt BIGINT
	       ,@RcptMtod VARCHAR(3);
   
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
         ,@AgopDesc = @X.query('//Aggregation_Operation').value('(Aggregation_Operation/@agopdesc)[1]'    , 'NVARCHAR(500)')
         ,@UnitBlokCndoCode = @X.query('//Aggregation_Operation').value('(Aggregation_Operation/@unitblokcndocode)[1]'    , 'VARCHAR(3)')
         ,@UnitBlokCode = @X.query('//Aggregation_Operation').value('(Aggregation_Operation/@unitblokcode)[1]'    , 'VARCHAR(3)')
         ,@UnitCode = @X.query('//Aggregation_Operation').value('(Aggregation_Operation/@unitcode)[1]'    , 'VARCHAR(3)')
         ,@SuntBuntDeptOrgnCode = @X.query('//Aggregation_Operation').value('(Aggregation_Operation/@suntbuntdeptorgncode)[1]'    , 'VARCHAR(2)')
         ,@SuntBuntDeptCode = @X.query('//Aggregation_Operation').value('(Aggregation_Operation/@suntbuntdeptcode)[1]'    , 'VARCHAR(2)')
         ,@SuntBuntCode = @X.query('//Aggregation_Operation').value('(Aggregation_Operation/@suntbuntcode)[1]'    , 'VARCHAR(2)')
         ,@SuntCode = @X.query('//Aggregation_Operation').value('(Aggregation_Operation/@suntcode)[1]'    , 'VARCHAR(4)')
         ,@LettNo = @X.query('//Aggregation_Operation').value('(Aggregation_Operation/@lettno)[1]'    , 'VARCHAR(15)')
         ,@LettDate = @X.query('//Aggregation_Operation').value('(Aggregation_Operation/@lettdate)[1]'    , 'DATETIME')
         ,@LettOwnr = @X.query('//Aggregation_Operation').value('(Aggregation_Operation/@lettownr)[1]'    , 'NVARCHAR(250)')
         ,@ExpnAmnt = @X.query('//Aggregation_Operation').value('(Aggregation_Operation/@expnamnt)[1]'    , 'BIGINT')
         ,@RcptMtod = @X.query('//Aggregation_Operation').value('(Aggregation_Operation/@rcptmtod)[1]'    , 'VARCHAR(3)');
   
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
   
   IF @FromDate = '1900-01-01' OR @FromDate IS NULL
      SELECT @FromDate = GETDATE();
   
   IF @TODate = '1900-01-01' OR @ToDate IS NULL
      SELECT @ToDate = GETDATE();
   
   SET @SuntBuntDeptOrgnCode = CASE LEN(@SuntBuntDeptOrgnCode) WHEN 2 THEN @SuntBuntDeptOrgnCode ELSE '00'   END;
   SET @SuntBuntDeptCode     = CASE LEN(@SuntBuntDeptCode)     WHEN 2 THEN @SuntBuntDeptCode     ELSE '00'   END;
   SET @SuntBuntCode         = CASE LEN(@SuntBuntCode)         WHEN 2 THEN @SuntBuntCode         ELSE '00'   END;
   SET @SuntCode             = CASE LEN(@SuntCode)             WHEN 4 THEN @SuntCode             ELSE '0000' END;
   
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
                AGOP_DESC,
                UNIT_BLOK_CNDO_CODE,
                UNIT_BLOK_CODE,
                UNIT_CODE,
                SUNT_BUNT_DEPT_ORGN_CODE,
                SUNT_BUNT_DEPT_CODE,
                SUNT_BUNT_CODE, 
                SUNT_CODE,
                LETT_NO,
                LETT_DATE,
                LETT_OWNR,
                EXPN_AMNT,
                RCPT_MTOD
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
                @AgopDesc,
                @UnitBlokCndoCode,
                @UnitBlokCode,
                @UnitCode,
                @SuntBuntDeptOrgnCode,
                @SuntBuntDeptCode,
                @SuntBuntCode,
                @SuntCode,
                @LettNo,
                @LettDate,
                @LettOwnr,
                @ExpnAmnt,
                @RcptMtod
              );
   END
   ELSE
   BEGIN
      -- 1400/01/01 * اگر دفتر بسته شود ولی میز هزینه دار درون آن وجود داشته باشد
      IF @OprtStat = '003'
      BEGIN
         IF EXISTS (SELECT * 
                      FROM dbo.Aggregation_Operation_Detail a
                     WHERE a.AGOP_CODE = @Code
                       AND a.RQST_RQID IS NULL)
         BEGIN
            -- 1400/01/01 * لاگ برداری از عملیات کاربر
   	      DECLARE @XTemp XML = (
   	         SELECT NULL AS '@fileno',
                      '005' AS '@type',
                      (
                        SELECT 
                               N'میز ' + ei.EPIT_DESC + N' از ساعت ' + CAST(a.STRT_TIME AS VARCHAR(5)) + N' شروع شده و تا ساعت ' + CAST(a.END_TIME AS VARCHAR(5)) + N' به مدت ' + CAST(a.TOTL_MINT_DNRM AS VARCHAR(10)) + N' دقیقه باز بوده که ارزش میز به مبلغ ' + 
                               REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, a.TOTL_AMNT_DNRM), 1), '.00', '') + N' بوده که توسط کاربر ' + UPPER(SUSER_NAME()) + N' حذف شده است.' + CHAR(10) + CHAR(10)
                          FROM dbo.Aggregation_Operation_Detail a, dbo.Expense e, dbo.Expense_Type et, dbo.Expense_Item ei
                         WHERE a.AGOP_CODE = @Code
                           AND e.CODE = a.EXPN_CODE
                           AND e.EXTP_CODE = et.CODE
                           AND et.EPIT_CODE = ei.CODE
                           AND a.RQST_RQID IS NULL
                           FOR XML PATH('')                           
                      ) AS '@text'
                 FROM dbo.Aggregation_Operation ao
                WHERE ao.CODE = @Code
                  FOR XML PATH('Log')
   	      );
   	      EXEC dbo.INS_LGOP_P @X = @XTemp; -- xml
         END 
      END
       
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
            ,UNIT_BLOK_CNDO_CODE = @UnitBlokCndoCode
            ,UNIT_BLOK_CODE = @UnitBlokCode
            ,UNIT_CODE = @UnitCode
            ,SUNT_BUNT_DEPT_ORGN_CODE = @SuntBuntDeptOrgnCode
            ,SUNT_BUNT_DEPT_CODE = @SuntBuntDeptCode
            ,SUNT_BUNT_CODE = @SuntBuntCode
            ,SUNT_CODE = @SuntCode
            ,LETT_NO = @LettNo
            ,LETT_DATE = @LettDate
            ,LETT_OWNR = @LettOwnr
            ,EXPN_AMNT = @ExpnAmnt
            ,RCPT_MTOD = @RcptMtod
      WHERE Code = @Code;
   END
END
GO
