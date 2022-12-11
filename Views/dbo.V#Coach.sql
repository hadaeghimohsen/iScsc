SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[V#Coach]
AS
SELECT     REGN_PRVN_CNTY_CODE, REGN_PRVN_CODE, REGN_CODE, FILE_NO, TARF_CODE_DNRM, MOST_DEBT_CLNG_DNRM, DEBT_DNRM, BUFE_DEBT_DNTM, DPST_AMNT_DNRM, 
                      FGPB_RWNO_DNRM, MBSP_RWNO_DNRM, MBCO_RWNO_DNRM, MBFZ_RWNO_DNRM, MBSM_RWNO_DNRM, CAMP_RWNO_DNRM, TEST_RWNO_DNRM, CLCL_RWNO_DNRM, 
                      HERT_RWNO_DNRM, PSFN_RWNO_DNRM, EXAM_RWNO_DNRM, BDFT_RWNO_DNRM, MBSP_STRT_DATE, MBSP_END_DATE, CONF_STAT, CONF_DATE, FIGH_STAT, RQST_RQID, 
                      NAME_DNRM, FRST_NAME_DNRM, LAST_NAME_DNRM, FATH_NAME_DNRM, POST_ADRS_DNRM, SEX_TYPE_DNRM, BRTH_DATE_DNRM, CELL_PHON_DNRM, TELL_PHON_DNRM, 
                      FGPB_TYPE_DNRM, INSR_NUMB_DNRM, INSR_DATE_DNRM, TEST_DATE_DNRM, CAMP_DATE_DNRM, CTGY_CODE_DNRM, MTOD_CODE_DNRM, CLUB_CODE_DNRM, COCH_FILE_NO_DNRM, 
                      COCH_CRTF_YEAR_DNRM, CBMT_CODE_DNRM, DAY_TYPE_DNRM, ATTN_TIME_DNRM, ACTV_TAG_DNRM, BLOD_GROP_DNRM, REF_CODE_DNRM, IMAG_RCDC_RCID_DNRM, 
                      IMAG_RWNO_DNRM, CARD_NUMB_DNRM, FNGR_PRNT_DNRM, SUNT_BUNT_DEPT_ORGN_CODE_DNRM, SUNT_BUNT_DEPT_CODE_DNRM, SUNT_BUNT_CODE_DNRM, SUNT_CODE_DNRM, 
                      CORD_X_DNRM, CORD_Y_DNRM, SERV_NO_DNRM, NATL_CODE_DNRM, GLOB_CODE_DNRM, CHAT_ID_DNRM, MOM_CELL_PHON_DNRM, MOM_TELL_PHON_DNRM, MOM_CHAT_ID_DNRM, 
                      DAD_CELL_PHON_DNRM, DAD_TELL_PHON_DNRM, DAD_CHAT_ID_DNRM, DPST_ACNT_SLRY_BANK_DNRM, DPST_ACNT_SLRY_DNRM, RTNG_NUMB_DNRM, CRET_BY, CRET_DATE, 
                      MDFY_BY, MDFY_DATE, ORGN_CODE_DNRM, LEFT_FILE_NO, RIGH_FILE_NO
FROM         dbo.Fighter
WHERE     (CONF_STAT = '002') AND (ACTV_TAG_DNRM >= '101') AND (FGPB_TYPE_DNRM IN ('003'))
GO
EXEC sp_addextendedproperty N'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Fighter"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 297
               Right = 320
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
', 'SCHEMA', N'dbo', 'VIEW', N'V#Coach', NULL, NULL
GO
DECLARE @xp int
SELECT @xp=1
EXEC sp_addextendedproperty N'MS_DiagramPaneCount', @xp, 'SCHEMA', N'dbo', 'VIEW', N'V#Coach', NULL, NULL
GO
