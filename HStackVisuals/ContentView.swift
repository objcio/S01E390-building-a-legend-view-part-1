//

import SwiftUI

struct HLine: View {
    var body: some View {
        Rectangle()
            .frame(height: 1)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DiagonalPattern: View {
    var body: some View {

        GeometryReader { proxy in
            let line = HLine()
                .frame(width: proxy.size.width*2)
                .rotationEffect(.degrees(-45))

            let o = proxy.size.width/2
            ZStack {
                line
                    .offset(x: -o, y: -o)
                line
                line
                    .offset(x: o, y: o)
            }
        }
    }
}

extension Image {
    @MainActor static func striped(environment: EnvironmentValues, size: CGFloat, scale: CGFloat) -> Image {
        let content = DiagonalPattern()
            .foregroundColor(.primary)
            .frame(width: size, height: size)
            .environment(\.self, environment)
        let renderer =  ImageRenderer(content: content)
        renderer.scale = scale
        return Image(renderer.cgImage!, scale: scale, label: Text(""))
    }
}

struct DiagonalStripes: ShapeStyle {
    var size: CGFloat = 16

    @MainActor func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
        .image(Image.striped(environment: environment, size: size, scale: environment.displayScale))
    }
}

struct LegendValue: PreferenceKey, Equatable {
    var bounds: Anchor<CGRect>
    var label: String
    var index: Int

    static let defaultValue: [LegendValue] = []
    static func reduce(value: inout [LegendValue], nextValue: () -> [LegendValue]) {
        value.append(contentsOf: nextValue())
    }
}

struct Legend: ViewModifier {
    @State private var items: [LegendValue] = []
    func body(content: Content) -> some View {
        VStack {
            content
                .onPreferenceChange(LegendValue.self, perform: { value in
                    self.items = value
                })
            VStack(alignment: .leading) {
                ForEach(Array(items.enumerated().reversed()), id: \.element.index) { (index, item) in
                    HStack {
                        Circle()
                            .frame(width: 3, height: 3)
                            .overlay {
                                GeometryReader { proxy in
                                    let f = proxy.frame(in: .local)
                                    let itemF = proxy[item.bounds]
                                    let height = f.midY - itemF.maxY
                                    Rectangle()
                                        .frame(width: 1)
                                        .frame(height: height)
                                        .offset(y: -height)
                                }
                                .frame(width: 1, height: 1)
                            }
                        Text(item.label)
                    }
                    .padding(.leading, .init(index) * 20)
                }
            }
        }
    }
}

extension View {
    func legend(_ label: String, index: Int) -> some View {
        transformAnchorPreference(key: LegendValue.self, value: .bounds, transform: { previous, anchor in
            previous.append(LegendValue(bounds: anchor, label: label, index: index))
        })
    }

    func drawLegend() -> some View {
        modifier(Legend())
    }
}

struct ContentView: View {
    var body: some View {
        let spacer =  Rectangle()
            .fill(DiagonalStripes())
            .frame(width: 8)
            .border(Color.primary)

        HStack(spacing: 0) {
            Color.blue
                .legend("Blue Rectangle", index: 0)
            spacer
                .legend("Spacer", index: 1)
            Text("Hello, world")
            spacer
            Color.green
        }
        .legend("HStack", index: 2)
        .drawLegend()
        .padding()
    }
}

#Preview {
    ContentView()
        .frame(width: 400, height: 300)
}
