/*
   Builda City, a multiplayer city building game.
   Copyright (C) 2021 Quentin Quaadgras

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU Affero General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU Affero General Public License for more details.

   You should have received a copy of the GNU Affero General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.

   Additional Terms according section 7 of GNU/GPL V3:

       "Builda City", "Splizard" and "Build a City" are trademarks of
       Quentin Quaadgras. If the licensee distributes modified copies
       of the Software then the licensee has to: Replace/remove
       all terms, images and files containing the marks "Builda City",
       "Splizard", "Build a City" and the Builda City logo. The copyright
       notices within the source code files may not be removed and have
       to be left fully intact. In addition, licensees that modify the
       Software must give the modified Software a new name that is not
       confusingly similar to "Builda City", "Splizard" or "Build a City"
       and may not distribute it under the names "Builda City", "Splizard"
       and/or "Build a City". The names "Builda City", "Splizard" and
       "Build a City" must not be used to endorse or promote products
       derived from this Software without prior written permission of
       Quentin Quaadgras.
*/

package main

import (
	"fmt"
	"image"
	"image/draw"
	"image/png"
	"os"
	"path"
	"strconv"

	"github.com/anthonynsimon/bild/transform"
)

//spintex creates rotation animations
//by spinning a texture. Output tex is
//named input + "_spinning.png"
//used for windturbine texture.
func main() {
	if len(os.Args) < 2 {
		fmt.Println("usage: spintex <texture> <frames=16>")
		os.Exit(1)
	}

	var name = os.Args[1]
	var frames = 16
	if len(os.Args) == 3 {
		frames, _ = strconv.Atoi(os.Args[2])
	}

	output, err := os.Create(name[:len(name)-len(path.Ext(name))] + "_spinning.png")
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	f, err := os.Open(name)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	img, _, err := image.Decode(f)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	var animation = image.NewNRGBA(image.Rect(0, 0, img.Bounds().Dx(), img.Bounds().Dy()*frames))

	for i := 0; i < frames; i++ {
		var frame = transform.Rotate(img, float64(i)*360.0/float64(frames), &transform.RotationOptions{
			Pivot: &image.Point{
				img.Bounds().Dx() / 2,
				img.Bounds().Dy() / 2,
			},
		})

		draw.Draw(animation, image.Rect(0, img.Bounds().Dy()*i, img.Bounds().Dx(), img.Bounds().Dy()*frames), frame, image.Point{}, draw.Src)
	}

	if err := png.Encode(output, animation); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
