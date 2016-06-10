source 'https://github.com/CocoaPods/Specs.git'

platform :osx, '10.10'
workspace 'CotEditor'


abstract_target 'app' do
    project 'CotEditor/CotEditor'

    pod 'YAML-Framework',
        :git => 'https://github.com/coteditor/YAML.framework.git',
        :branch => 'coteditor-mod'
    pod 'NSHash'
    pod 'WFColorCode'


    target 'CotEditor' do
        pod 'Sparkle'
    end

    target 'CotEditor -AppStore'
end


target 'Tests' do
    project 'CotEditor/CotEditor'

    pod 'YAML-Framework',
        :git => 'https://github.com/coteditor/YAML.framework.git',
        :branch => 'coteditor-mod'
    pod 'WFColorCode'
end
