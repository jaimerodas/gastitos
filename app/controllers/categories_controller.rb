class CategoriesController < ApplicationController
  before_action :require_login
  before_action :require_editor

  def create
    @category = Category.new(category_params)

    if @category.save
      render json: { id: @category.id, name: @category.name, category_type: @category.category_type }, status: :created
    else
      render json: { errors: @category.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def category_params
    params.expect(category: [ :name, :category_type ])
  end
end
