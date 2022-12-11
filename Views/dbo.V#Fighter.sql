SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[V#Fighter]
AS
SELECT     dbo.Fighter.REGN_PRVN_CNTY_CODE, dbo.Fighter.REGN_PRVN_CODE, dbo.Fighter.REGN_CODE, dbo.Fighter.FILE_NO, dbo.Fighter.TARF_CODE_DNRM, dbo.Fighter.MOST_DEBT_CLNG_DNRM, 
                      dbo.Fighter.DEBT_DNRM, dbo.Fighter.BUFE_DEBT_DNTM, dbo.Fighter.DPST_AMNT_DNRM, dbo.Fighter.FGPB_RWNO_DNRM, dbo.Fighter.MBSP_RWNO_DNRM, dbo.Fighter.MBCO_RWNO_DNRM, 
                      dbo.Fighter.MBFZ_RWNO_DNRM, dbo.Fighter.MBSM_RWNO_DNRM, dbo.Fighter.CAMP_RWNO_DNRM, dbo.Fighter.TEST_RWNO_DNRM, dbo.Fighter.CLCL_RWNO_DNRM, 
                      dbo.Fighter.HERT_RWNO_DNRM, dbo.Fighter.PSFN_RWNO_DNRM, dbo.Fighter.EXAM_RWNO_DNRM, dbo.Fighter.BDFT_RWNO_DNRM, dbo.Fighter.MBSP_STRT_DATE, 
                      dbo.Fighter.MBSP_END_DATE, dbo.Fighter.CONF_STAT, dbo.Fighter.CONF_DATE, dbo.Fighter.FIGH_STAT, dbo.Fighter.RQST_RQID, dbo.Fighter.NAME_DNRM, dbo.Fighter.FRST_NAME_DNRM, 
                      dbo.Fighter.LAST_NAME_DNRM, dbo.Fighter.FATH_NAME_DNRM, dbo.Fighter.POST_ADRS_DNRM, dbo.Fighter.SEX_TYPE_DNRM, dbo.Fighter.BRTH_DATE_DNRM, dbo.Fighter.CELL_PHON_DNRM,
                       dbo.Fighter.TELL_PHON_DNRM, dbo.Fighter.FGPB_TYPE_DNRM, dbo.Fighter.INSR_NUMB_DNRM, dbo.Fighter.INSR_DATE_DNRM, dbo.Fighter.TEST_DATE_DNRM, 
                      dbo.Fighter.CAMP_DATE_DNRM, dbo.Fighter.CTGY_CODE_DNRM, dbo.Fighter.MTOD_CODE_DNRM, dbo.Fighter.CLUB_CODE_DNRM, dbo.Fighter.COCH_FILE_NO_DNRM, 
                      dbo.Fighter.COCH_CRTF_YEAR_DNRM, dbo.Fighter.CBMT_CODE_DNRM, dbo.Fighter.DAY_TYPE_DNRM, dbo.Fighter.ATTN_TIME_DNRM, dbo.Fighter.ACTV_TAG_DNRM, 
                      dbo.Fighter.BLOD_GROP_DNRM, dbo.Fighter.REF_CODE_DNRM, dbo.Fighter.IMAG_RCDC_RCID_DNRM, dbo.Fighter.IMAG_RWNO_DNRM, dbo.Fighter.CARD_NUMB_DNRM, 
                      dbo.Fighter.FNGR_PRNT_DNRM, dbo.Fighter.SUNT_BUNT_DEPT_ORGN_CODE_DNRM, dbo.Fighter.SUNT_BUNT_DEPT_CODE_DNRM, dbo.Fighter.SUNT_BUNT_CODE_DNRM, 
                      dbo.Fighter.SUNT_CODE_DNRM, dbo.Fighter.CORD_X_DNRM, dbo.Fighter.CORD_Y_DNRM, dbo.Fighter.SERV_NO_DNRM, dbo.Fighter.NATL_CODE_DNRM, dbo.Fighter.GLOB_CODE_DNRM, 
                      dbo.Fighter.CHAT_ID_DNRM, dbo.Fighter.MOM_CELL_PHON_DNRM, dbo.Fighter.MOM_TELL_PHON_DNRM, dbo.Fighter.MOM_CHAT_ID_DNRM, dbo.Fighter.DAD_CELL_PHON_DNRM, 
                      dbo.Fighter.DAD_TELL_PHON_DNRM, dbo.Fighter.DAD_CHAT_ID_DNRM, dbo.Fighter.DPST_ACNT_SLRY_BANK_DNRM, dbo.Fighter.DPST_ACNT_SLRY_DNRM, dbo.Fighter.RTNG_NUMB_DNRM, 
                      dbo.Fighter.CRET_BY, dbo.Fighter.CRET_DATE, dbo.Fighter.MDFY_BY, dbo.Fighter.MDFY_DATE, dbo.Fighter.ORGN_CODE_DNRM, dbo.Fighter.LEFT_FILE_NO, dbo.Fighter.RIGH_FILE_NO, 
                      dbo.Sub_Unit.SUNT_DESC, dbo.D$SXTP.DOMN_DESC AS SEX_DESC
FROM         dbo.Fighter INNER JOIN
                      dbo.V#UCFGA ON dbo.Fighter.CLUB_CODE_DNRM = dbo.V#UCFGA.CLUB_CODE INNER JOIN
                      dbo.Sub_Unit ON dbo.Fighter.SUNT_BUNT_DEPT_ORGN_CODE_DNRM = dbo.Sub_Unit.BUNT_DEPT_ORGN_CODE AND 
                      dbo.Fighter.SUNT_BUNT_DEPT_CODE_DNRM = dbo.Sub_Unit.BUNT_DEPT_CODE AND dbo.Fighter.SUNT_BUNT_CODE_DNRM = dbo.Sub_Unit.BUNT_CODE AND 
                      dbo.Fighter.SUNT_CODE_DNRM = dbo.Sub_Unit.CODE INNER JOIN
                      dbo.D$SXTP ON dbo.Fighter.SEX_TYPE_DNRM = dbo.D$SXTP.VALU
WHERE     (dbo.Fighter.CONF_STAT = '002') AND (dbo.Fighter.ACTV_TAG_DNRM >= '101') AND (dbo.V#UCFGA.SYS_USER = UPPER(SUSER_NAME()))
GO
EXEC sp_addextendedproperty N'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[14] 2[29] 3) )"
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
               Bottom = 296
               Right = 321
            End
            DisplayFlags = 280
            TopColumn = 24
         End
         Begin Table = "V#UCFGA"
            Begin Extent = 
               Top = 6
               Left = 358
               Bottom = 126
               Right = 530
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Sub_Unit"
            Begin Extent = 
               Top = 244
               Left = 359
               Bottom = 411
               Right = 574
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "D$SXTP"
            Begin Extent = 
               Top = 134
               Left = 359
               Bottom = 224
               Right = 530
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
      Begin ColumnWidths = 80
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500', 'SCHEMA', N'dbo', 'VIEW', N'V#Fighter', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_DiagramPane2', N'
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
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
', 'SCHEMA', N'dbo', 'VIEW', N'V#Fighter', NULL, NULL
GO
DECLARE @xp int
SELECT @xp=2
EXEC sp_addextendedproperty N'MS_DiagramPaneCount', @xp, 'SCHEMA', N'dbo', 'VIEW', N'V#Fighter', NULL, NULL
GO
