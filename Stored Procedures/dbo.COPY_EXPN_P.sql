SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[COPY_EXPN_P]
	@REGL_YEAR SMALLINT,
	@REGL_CODE SMALLINT
AS
BEGIN
	-- بررسی اینکه آیا آیین نامه هزینه فعالی درون سیستم هست که بتوان از اطلاعات هزینه آن کپی برداری کرد یا خیر؟
   IF NOT EXISTS(
      SELECT *
        FROM Regulation
       WHERE TYPE = '001' -- آیین نامه حساب
         AND REGL_STAT = '002' -- فعال
   )   
      GOTO L$End;
      
   -- آیین نامه هزینه فعال درون سیستم وجود دارد
   DECLARE C$RegulationExpense CURSOR FOR
   SELECT * FROM V#Regulation_Expense
   WHERE TYPE = '001'
     AND REGL_STAT = '002';
   
   DECLARE @ReglYear SMALLINT
          ,@ReglCode INT
          ,@SubSys   SMALLINT
          ,@Type     VARCHAR(3)
          ,@ReglStat VARCHAR(3)
          ,@ExtpCode BIGINT
          ,@CtgyCode BIGINT
          ,@MtodCode BIGINT
          ,@ExpnCode BIGINT
          ,@Pric     INT
          ,@ExtrPric INT
          ,@ExpnStat VARCHAR(3)
          ,@AddQust VARCHAR(3)
          ,@CovrDsct VARCHAR(3)
          ,@ExpnType VARCHAR(3)
          ,@BuyPric INT
          ,@BuyExtrPrct INT
          ,@NumbOfStok INT
          ,@NumbOfSale INT
          ,@NumbOfRemnDnrm INT
          ,@OrdrItem BIGINT
          ,@CovrTax VARCHAR(3)
          ,@NumbOfAttnMont INT
          ,@NumbOfAttnWeek INT
          ,@ModlNumbBarCode VARCHAR(50)
          ,@PrvtCochExpn VARCHAR(3)
          ,@MinNumb INT
          ,@GropCode BIGINT
          ,@MinTime DATETIME;
   
   OPEN C$RegulationExpense;
   L$NextRERow:
   FETCH NEXT FROM C$RegulationExpense
   INTO @ReglYear
       ,@ReglCode
       ,@SubSys
       ,@Type
       ,@ReglStat
       ,@ExtpCode
       ,@CtgyCode
       ,@MtodCode
       ,@ExpnCode
       ,@Pric
       ,@ExtrPric
       ,@ExpnStat
       ,@AddQust
       ,@CovrDsct
       ,@ExpnType
       ,@BuyPric
       ,@BuyExtrPrct
       ,@NumbOfStok
       ,@NumbOfSale
       ,@NumbOfRemnDnrm
       ,@OrdrItem
       ,@CovrTax
       ,@NumbOfAttnMont
       ,@NumbOfAttnWeek
       ,@ModlNumbBarCode
       ,@PrvtCochExpn
       ,@MinNumb
       ,@GropCode
       ,@MinTime;
       
   IF @@FETCH_STATUS <> 0
      GOTO L$EndFetchRE;

   IF NOT EXISTS(
      SELECT * 
      FROM V#Regulation_Expense
      WHERE YEAR = @REGL_YEAR
        AND CODE = @REGL_CODE
        AND SUB_SYS = @SubSys
        AND TYPE    = @Type
        AND REGL_STAT = @ReglStat
        AND EXTP_CODE = @ExtpCode
        AND CTGY_CODE = @CtgyCode
        AND MTOD_CODE = @MtodCode
   )
   BEGIN
      --PRINT CAST(@Regl_Year AS VARCHAR(MAX)) + ', ' + CAST(@Regl_Code AS VARCHAR(MAX)) + ', ' + CAST(@CtgyCode AS VARCHAR(MAX)) + ', ' + CAST(@MtodCode AS VARCHAR(MAX)) + ', ' + CAST(@ExtpCode AS VARCHAR(MAX));
      --PRINT dbo.Gnrt_Nvid_U();
      INSERT INTO Expense (REGL_YEAR,  REGL_CODE,  EXTP_CODE, CTGY_CODE, MTOD_CODE, PRIC,  EXPN_STAT, ADD_QUTS, COVR_DSCT, Expn_Type, Buy_Pric, Buy_Extr_Prct, Numb_Of_Stok, Numb_Of_Sale, Numb_Of_Remn_Dnrm, ORDR_ITEM, COVR_TAX, NUMB_OF_ATTN_MONT, NUMB_OF_ATTN_WEEK, MODL_NUMB_BAR_CODE, PRVT_COCH_EXPN, MIN_NUMB, GROP_CODE, MIN_TIME)
      VALUES             (@REGL_YEAR, @REGL_CODE, @ExtpCode, @CtgyCode, @MtodCode, @Pric, @ExpnStat, @AddQust, @CovrDsct, @ExpnType, @BuyPric, @BuyExtrPrct, @NumbOfStok, @NumbOfSale, @NumbOfRemnDnrm, @OrdrItem, @CovrTax, @NumbOfAttnMont, @NumbOfAttnWeek, @ModlNumbBarCode, @PrvtCochExpn, @MinNumb, @GropCode, @MinTime);
   END
   
   GOTO L$NextRERow;
   L$EndFetchRE:
   CLOSE C$RegulationExpense;
   DEALLOCATE C$RegulationExpense;   

   L$End:
   RETURN;
END
GO
