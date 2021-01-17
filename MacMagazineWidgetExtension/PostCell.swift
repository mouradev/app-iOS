//
//  PostCell.swift
//  MacMagazineWidgetExtensionExtension
//
//  Created by Ailton Vieira Pinto Filho on 16/01/21.
//  Copyright © 2021 MacMagazine. All rights reserved.
//

import SwiftUI
import WidgetKit

struct PostCell: View {
    @Environment(\.widgetFamily) var widgetFamily
    @Environment(\.redactionReasons) var redactionReasons
    
    let post: PostData
    let style: Style
    
    enum Style { case cover, row }
    
    var image: Image {
        if redactionReasons == .placeholder {
            return Image("widgetPlaceholder")
        } else {
            if let imageData = post.image {
                return Image(uiImage: UIImage(data: imageData)!)
            } else {
                return Image("widgetPlaceholder")
            }
        }
    }
    
    var coverImage: some View {
        image.resizable()
            .scaledToFill()
            .unredacted()
    }
    
    var title: some View {
        HStack {
            Text(post.title)
                .font(.caption)
                .bold()
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
    }
    
    var body: some View {
        switch style {
        case .cover:
            coverStyle
        case .row:
            rowStyle
        }
    }
    
    var coverStyle: some View {
        VStack {
            HStack {
                Spacer()
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30)
                    .unredacted()
            }
            .shadow(color: Color.black.opacity(0.2), radius: 1)
            .padding([.top, .trailing])
            
            Spacer()
            
            VStack {
                HStack {
                    title
                    Spacer()
                }
                if widgetFamily == .systemLarge {
                    HStack {
                        Text(post.description)
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                        Spacer()
                    }
                }
            }
            .shadow(color: .black, radius: 5)
            .padding()
            .background(
                LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.01), Color.black]), startPoint: .top, endPoint: .bottom))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
        .background(coverImage)
        .background(Color.white)
        .clipped()
    }
    
    var rowStyle: some View {
        GeometryReader { geo in
            HStack {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 0.2 * geo.size.width, height: geo.size.height)
                    .clipped()
                    .cornerRadius(8)
                VStack {
                    Spacer()
                    title
                    if widgetFamily == .systemLarge {
                        HStack {
                            Text(post.description)
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                            Spacer()
                        }
                    }
                    Spacer()
                }
            }
        }
    }
}

struct PostCell_Previews: PreviewProvider {
    static var previews: some View {
        PostCell(post: .placeholder, style: .cover)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        VStack {
            PostCell(post: .placeholder, style: .row)
            PostCell(post: .placeholder, style: .row)
        }.padding()
            .previewContext(WidgetPreviewContext(family: .systemMedium))
//            .redacted(reason: .placeholder)
        GeometryReader { geo in
            VStack {
                PostCell(post: .placeholder, style: .cover)
                    .frame(height: 0.5 * geo.size.height)
                VStack {
                    PostCell(post: .placeholder, style: .row)
                    PostCell(post: .placeholder, style: .row)
                }.padding()
            }
        }
        .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
