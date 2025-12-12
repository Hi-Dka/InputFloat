//
//  SettingsView.swift
//  InputFloat
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var config: FloatWindowConfig
    @ObservedObject var monitor: InputMethodMonitor
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView{
            VStack(alignment: .leading, spacing: 0){
                
                SettingsSection(title: "颜色设置"){
                    VStack(){
                        ColorSchemeSelector(config: config)
                        
                        VStack {
                            FloatingWindowView(monitor: monitor, config: config)
                            
                            HStack(spacing:20) {
                                ColorPicker(selection: $config.textColor){EmptyView()}
                                    .labelsHidden()
                                    .frame(width: 30, height: 30)
                               
                                Button(
                                    action: {
                                        let tempColor = config.textColor
                                        config.textColor = config.backgroundColor
                                        config.backgroundColor = tempColor
                                    },
                                    label: {
                                        Image(systemName: "repeat")
                                    }
                                )
                                
                                ColorPicker(selection: $config.backgroundColor){EmptyView()}
                                    .labelsHidden()
                                    .frame(width: 30, height: 30)
                                
                            }.frame(maxWidth: .infinity)
                        }.padding(25)
                            .background(RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color(red: 0.97, green: 0.97, blue: 0.97)))
                            )
                    }
                }
                
                SettingsSection(title: "指示器大小"){
                        Picker(selection: Binding(
                            get: {
                                if config.fontSize <= 16 {
                                    return FontSizeOption.small
                                } else if config.fontSize <= 20 {
                                    return FontSizeOption.medium
                                } else {
                                    return FontSizeOption.large
                                }
                            },
                            set: { newValue in
                                config.fontSize = newValue.size
                            }
                        )) {
                            ForEach(FontSizeOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        } label: { EmptyView() }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                }
                
                SettingsSection(title: "指示器不透明度") {
                    HStack{
                        Slider(value: Binding(get:{config.opacity * 100}, set:{config.opacity = $0 / 100}),in: 30...100,step:5)
                        Text(String(format: "%.0f%%", config.opacity * 100))
                            .frame(width: 50)
                    }
                }
                
                SettingsSection(title: "系统设置") {
                    VStack{
                        Toggle(isOn: $config.autoStart){
                            HStack{
                                Text("开机自动启动")
                                    .lineLimit(1)
                                Spacer()
                            }
                        }.toggleStyle(.switch).padding(.bottom,4)
                        
                        Divider()
                        
                        HStack{
                           Text("重置为默认设置")
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Button(action:{
                                    config.resetToDefaults()
                                },
                                label: {
                                    Image(systemName: "arrow.uturn.backward")
                            })
                        }.padding(.top,4)
                    }
                }
            }
        }
        .frame(width:550, height:680)
        .background(Color(red: 0.97, green: 0.97, blue: 0.97))
        

    }
}

#Preview {
    SettingsView(config: FloatWindowConfig.shared, monitor: InputMethodMonitor())
}
