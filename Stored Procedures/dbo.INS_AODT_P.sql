SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_AODT_P]
	-- Add the parameters for the stored procedure here
    @Agop_Code BIGINT ,
    @Rwno INT ,
    @Aodt_Agop_Code BIGINT ,
    @Aodt_Rwno INT ,
    @Figh_File_No BIGINT ,
    @Rqst_Rqid BIGINT ,
    @Attn_Code BIGINT ,
    @Coch_File_No BIGINT ,
    @Rec_Stat VARCHAR(3) ,
    @Stat VARCHAR(3) ,
    @Expn_Code BIGINT ,
    @Min_Mint_Step TIME(0) ,
    @Strt_Time TIME(0) ,
    @End_Time TIME(0) ,
    @Expn_Pric INT ,
    @Expn_Extr_Prct INT ,
    @Cust_Name NVARCHAR(250) ,
    @Cell_Phon VARCHAR(11) ,
    @Fngr_Prnt VARCHAR(20),
    @Grop_Apbs_Code BIGINT,
    @Expr_Mint_Numb INT
AS
BEGIN
BEGIN TRY   
BEGIN TRAN [T$INS_AODT_P]
  IF @Figh_File_No = 0 SET @Figh_File_No = NULL;
  
  IF @Fngr_Prnt IS NULL AND 
     (@Figh_File_No IS NULL OR 
      @Figh_File_No = 0 )
  BEGIN
      SELECT TOP 1
              @Figh_File_No = FILE_NO
      FROM    dbo.Fighter
      WHERE   FGPB_TYPE_DNRM = '005';
  END 
  
  IF @Figh_File_No IS NULL AND @Fngr_Prnt IS NULL RETURN;
  
  -- 1399/11/25 * اگر مشتری قبلا برای میزی باز شده باشد آیا این اجازه را داریم که دوباره میز دیگری برایش باز کنیم یا خیر
  IF EXISTS(SELECT * FROM dbo.Aggregation_Operation_Detail a WHERE a.AGOP_CODE = @Agop_Code AND a.FIGH_FILE_NO = @Figh_File_No AND a.REC_STAT = '002' AND a.STAT = '001')
  BEGIN
      DECLARE @AP BIT
             ,@AccessString VARCHAR(250);
      SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>248</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
      EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
      IF @AP = 0 
      BEGIN
         RAISERROR ( N'خطا - عدم دسترسی به ردیف 248 سطوح امینتی', -- Message text.
                  16, -- Severity.
                  1 -- State.
                  );
         RETURN;
      END
  END 
   
  INSERT  dbo.Aggregation_Operation_Detail
          ( AGOP_CODE ,
            RWNO ,
            AODT_AGOP_CODE ,
            AODT_RWNO ,
            FIGH_FILE_NO ,
            RQST_RQID ,
            ATTN_CODE ,
            COCH_FILE_NO ,
            DEBT_AMNT ,
            REC_STAT ,
            STAT ,
            EXPN_CODE ,
            MIN_MINT_STEP ,
            STRT_TIME ,
            END_TIME ,
            TOTL_MINT_DNRM ,
            EXPN_PRIC ,
            EXPN_EXTR_PRCT ,
            REMN_PRIC ,
            TOTL_BUFE_AMNT_DNRM ,
            TOTL_AMNT_DNRM ,
            CUST_NAME ,
            CELL_PHON ,
            CASH_AMNT,
            POS_AMNT,
            PYDS_AMNT,
            DPST_AMNT,
            FNGR_PRNT,
            GROP_APBS_CODE,
            EXPR_MINT_NUMB
         )
  VALUES  ( @Agop_Code ,
            0 ,
            @Aodt_Agop_Code ,
            @Aodt_Rwno ,
            @Figh_File_No , -- FIGH_FILE_NO - bigint
            @Rqst_Rqid , -- RQST_RQID - bigint
            @Attn_Code , -- ATTN_CODE - bigint
            @Coch_File_No , -- COCH_FILE_NO - bigint
            NULL , -- DEBT_AMNT - bigint
            '002' , -- REC_STAT - varchar(3)
            '001' , -- STAT - varchar(3)
            @Expn_Code , -- EXPN_CODE - bigint
            ( SELECT  CASE WHEN MIN_TIME IS NULL THEN '00:05:00'
                           ELSE CAST(MIN_TIME AS TIME(0))
                      END
              FROM    dbo.Expense
              WHERE   CODE = @Expn_Code
            ) , -- MIN_MINT_STEP - time
            GETDATE() , -- STRT_TIME - time
            NULL , -- END_TIME - time
            0 , -- TOTL_MINT_DNRM - int
            0 , -- EXPN_PRIC - int
            0 , -- EXPN_EXTR_PRCT - int
            0 , -- REMN_PRIC - int
            0 , -- TOTL_BUFE_AMNT_DNRM - bigint
            0 , -- TOTL_AMNT_DNRM - bigint
            N'' ,  -- CUST_NAME - nvarchar(250)
            '' ,
            0,
            0, 
            0,
            0,
            @Fngr_Prnt,
            @Grop_Apbs_Code,
            @Expr_Mint_Numb
         );
COMMIT TRAN [T$INS_AODT_P]
END TRY
BEGIN CATCH
   DECLARE @ErorMesg NVARCHAR(Max) = ERROR_MESSAGE();
   RAISERROR(@ErorMesg, 16, 1);
   ROLLBACK TRAN [T$INS_AODT_P];   
END CATCH
END;
GO
