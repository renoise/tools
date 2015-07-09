--[[----------------------------------------------------------------------------
-- Duplex.Launch Control XL
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

-- configuration properties
    name = "Mutes",
    pinned = true,
  
-- device properties
    device = {
        -- class_name = nil,
		class_name = "Launchpad",
        display_name = "Launch Control XL",
        device_port_in = "Launch Control XL",
        device_port_out = "Launch Control XL",
        control_map = "Controllers/Launch-Control-XL/Controlmaps/01_Mutes.xml",
        thumbnail = "Controllers/Launch-Control-XL/Launch-Control-XL.bmp",
        protocol = DEVICE_PROTOCOL.MIDI,
    },

    applications = {
    
        Effect = {
            mappings = {
                parameters = {
					group_name = "DeviceEncoders"
				},
                device_prev = {
					group_name = "DeviceSelect",
					index = 1
				},
                device_next = {
					group_name = "DeviceSelect",
					index = 2
				}
            },
            palette = {
                prev_device_on = {
                    color = {0xFF,0x00,0x00},
                    text = "▴",
                    val = true
                },
                prev_device_off = {
                    text = "▴",
                    val = false
                },
                next_device_on = {
                    color = {0xFF,0x00,0x00},
                    text = "▾",
                    val = true
                },
                next_device_off = {
                    text = "▾",
                    val = false
                }
            }
        },

        Mixer = {
            application = "Mixer",
            mappings = {
                panning = {group_name = "PanEncoders"},
                levels = {group_name = "VolumeFaders"},
				mute = {group_name = "MuteButtons"}
            },
            options = {
                pre_post = 2,
                follow_track = 1,
                take_over_volumes = 2,
                page_size = 8
            },
            palette = {
                normal_mute_on = {
                    color = {0xFF,0x88,0x00},
                    val = true
                },
                normal_mute_off = {
                    color = {0xFF,0x00,0x00},
                    val = false
                }
            }
        },

        TrackSelector = {
            mappings = {
                prev_page = {
					group_name = "PageSelectors",
					index = 1
				},
                next_page = {
					group_name = "PageSelectors",
					index = 2
				},
                select_track = {
					group_name = "TrackSelection",
					index = 1
				}
            },
            palette = {
                select_device_tip = {
                    color = {0x00,0xFF,0x00},
                    text = "▬",
                    val = true
                },
                select_device_back = {
                    color = {0x00,0x00,0x00},
                    text = "▬",
                    val = false
                },
                page_prev_on = {
                    color = {0xFF,0x00,0x00},
                    text = "◂",
                    val = true
                },
                page_prev_off = {
                    text = "◂",
                    val = false
                },
                page_next_on = {
                    color = {0xFF,0x00,0x00},
                    text = "▸",
                    val = true
                },
                page_next_off = {
                    text = "▸",
                    val = false
                }
            }
        },

		Transport = {
			mappings = {
				edit_mode = {
					group_name = "Modes",
					index = 1
				}
			},
            palette = {
                edit_mode_off = {
                    color = {0x00,0x00,0x00},
                    text = "●",
                    val = false
                },
                edit_mode_on = {
                    color = {0xFF,0x80,0x00},
                    text = "●",
                    val = true
                },
            }
		},
		
		SwitchConfiguration = {
			mappings = {
				goto_1 = {
					group_name = "Modes",
					index = 2
				},
				goto_2 = {
					group_name = "Modes",
					index = 3
				},
				goto_3 = {
					group_name = "Modes",
					index = 4
				}
			},
			palette = {
				set_config_on = {
					color = {0xFF,0x80,0x00},
					text = "",
					val = true
				},
				set_config_off = {
					color = {0x00,0x00,0x00},
					text = "",
					val = false
				}
			}
		}
    }
}